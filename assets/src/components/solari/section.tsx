import React from "react";
import { CSSTransition, TransitionGroup } from "react-transition-group";

import Departure from "Components/solari/departure";
import HeadwayDeparture from "Components/solari/headway_departure";
import Arrow, { Direction } from "Components/solari/arrow";
import {
  SectionRoutePill,
  PagedDepartureRoutePill,
} from "Components/solari/route_pill";
import BaseDepartureDestination from "Components/eink/base_departure_destination";
import { classWithModifier, classWithModifiers, imagePath } from "Util/util";
import { standardTimeRepresentation } from "Util/time_representation";
import moment from "moment";

const WIDE_MINI_PILL_ROUTES = ["441/442"];

const camelizeDepartureObject = ({
  id,
  route,
  destination,
  time,
  route_id: routeId,
  vehicle_status: vehicleStatus,
  alerts,
  stop_type: stopType,
  crowding_level: crowdingLevel,
  track_number: trackNumber,
}) => ({
  id,
  route,
  destination,
  time,
  routeId,
  vehicleStatus,
  alerts,
  stopType,
  crowdingLevel,
  trackNumber,
});

const isArrivingOrBoarding = (
  { time, vehicle_status, stop_type },
  currentTimeString,
) => {
  const timeRepresentation = standardTimeRepresentation(
    time,
    currentTimeString,
    vehicle_status,
    stop_type,
  );
  return (
    timeRepresentation.type === "TEXT" &&
    ["ARR", "BRD"].includes(timeRepresentation.text)
  );
};

const verticalHeaderIconSrc = (name, departuresLength) => {
  let iconFileName = "";
  switch (true) {
    case departuresLength <= 1 && name === "Upper Busway":
      iconFileName = "icon-upper-busway-arrow-only.svg";
      break;
    case departuresLength <= 1 && name === "Lower Busway":
      iconFileName = "icon-lower-busway-arrow-only.svg";
      break;
    case name === "Upper Busway":
      iconFileName = "icon-upper-busway.svg";
      break;
    case name === "Lower Busway":
      iconFileName = "icon-lower-busway.svg";
      break;
    case name === "Commuter Rail":
      iconFileName = "icon-commuter-rail.svg";
      break;
  }
  return imagePath(iconFileName);
};

const SectionHeader = ({ name, arrow }): JSX.Element => {
  return (
    <div className="section-header">
      <span className="section-header__name">{name}</span>
      {arrow !== null && (
        <span className="section-header__arrow-container">
          <Arrow direction={arrow} className="section-header__arrow-image" />
        </span>
      )}
    </div>
  );
};

const SectionFrame = ({
  sectionHeaders,
  name,
  arrow,
  overhead,
  departuresLength,
  children,
}): JSX.Element => {
  const sectionModifier = sectionHeaders === "vertical" ? "vertical" : "normal";
  const sectionClass = classWithModifier("section", sectionModifier);
  const shouldShowHeader =
    sectionHeaders !== "none" && name !== null && !overhead;

  if (sectionHeaders === "vertical") {
    const iconSrc = verticalHeaderIconSrc(name, departuresLength);

    name = <img className="section-header__icon" src={iconSrc} />;
  }

  return (
    <div className={sectionClass}>
      {shouldShowHeader && <SectionHeader name={name} arrow={arrow} />}
      <div className="departures-container">{children}</div>
    </div>
  );
};

const PlaceholderMessage = ({ pill, text }): JSX.Element => (
  <div
    className={classWithModifiers("departure-container", [
      "group-start",
      "group-end",
    ])}
  >
    <div className={classWithModifier("departure", "no-via")}>
      <SectionRoutePill pill={pill} />
      <div
        className={classWithModifier(
          "departure-destination",
          "no-departures-placeholder",
        )}
      >
        <BaseDepartureDestination destination={text} />
      </div>
    </div>
  </div>
);

const isDuringSurge = () => {
  const now = moment();
  const isDuringFirstRange = now.isBetween(
    moment("2024-01-03T09:30:00Z"),
    moment("2024-01-13T07:30:00Z"),
  );

  const isDuringSecondRange = now.isBetween(
    moment("2024-01-16T09:30:00Z"),
    moment("2024-01-29T07:30:00Z"),
  );

  return isDuringFirstRange || isDuringSecondRange;
};

const NoDeparturesMessage = ({ pill, stationName }): JSX.Element => {
  let placeholderText = "No departures currently available";

  if (stationName === "Haymarket" && isDuringSurge()) {
    placeholderText = "Service Suspended";
  }

  return <PlaceholderMessage pill={pill} text={placeholderText} />;
};

const NoDataMessage = ({ pill }): JSX.Element => {
  return (
    <PlaceholderMessage pill={pill} text="Live updates currently unavailable" />
  );
};

interface PagedDepartureProps {
  pageCount: number;
  departures: object[];
  overhead: boolean;
}

interface PagedDepartureState {
  currentPageNumber: number;
}

class PagedDeparture extends React.Component<
  PagedDepartureProps,
  PagedDepartureState
> {
  interval: number | null;

  constructor(props: PagedDepartureProps) {
    super(props);
    this.state = { currentPageNumber: 0 };
    this.interval = null;
  }

  componentDidMount() {
    this.startPaging();
  }

  componentWillUnmount() {
    this.stopPaging();
  }

  componentDidUpdate(prevProps) {
    if (!this.propsEqual(prevProps)) {
      this.stopPaging();
      this.setState({ currentPageNumber: 0 });
      this.startPaging();
    }
  }

  propsEqual(otherProps) {
    const { pageCount, departures } = this.props;
    return (
      pageCount === otherProps.pageCount &&
      departures.length === otherProps.departures.length &&
      // @ts-expect-error
      departures.every((d, i) => d.id === otherProps.departures[i].id)
    );
  }

  startPaging() {
    const refreshMs = this.pageDuration();
    if (refreshMs !== null) {
      this.interval = window.setInterval(
        this.updatePaging.bind(this),
        refreshMs,
      );
    }
  }

  stopPaging() {
    if (this.interval) {
      clearInterval(this.interval);
      this.interval = null;
    }
  }

  updatePaging() {
    this.setState((state: PagedDepartureState, props: PagedDepartureProps) => {
      if (props.pageCount === 0) {
        return { currentPageNumber: 0 };
      } else {
        return {
          currentPageNumber: (state.currentPageNumber + 1) % props.pageCount,
        };
      }
    });
  }

  pageDuration() {
    if (this.props.pageCount <= 1) {
      // Don't set an interval if there are 0 or 1 pages
      return null;
    } else if (this.props.pageCount === 2) {
      return 3750;
    } else {
      return 15000 / this.props.pageCount;
    }
  }

  render() {
    // Don't show alert badges in the paging row
    const currentPagedDeparture = {
      ...this.props.departures[this.state.currentPageNumber],
      alerts: [],
    };

    // Determine whether all route pills are small.
    // If route pills differ in size, we need to adjust the position of the small ones.
    // If all route pills are the same size, we don't want to make any adjustment.
    const isSmall = (departure) =>
      departure.route_id.startsWith("CR-") || departure.route.includes("/");
    const sizeModifier = this.props.departures.every(isSmall)
      ? "size-small"
      : "size-normal";

    const normalPillWidth = 89; // px
    const widePillWidth = 158; // px
    const pillSpace = 25; // px

    const selectedRightOffset =
      this.props.pageCount - (this.state.currentPageNumber + 1);
    const numWidePillsToTheRight = this.props.departures
      .slice(this.state.currentPageNumber + 1)
      // @ts-expect-error
      .filter(({ route }) => WIDE_MINI_PILL_ROUTES.includes(route)).length;
    const numNormalPillsToTheRight =
      selectedRightOffset - numWidePillsToTheRight;

    const currentPillIsWide = WIDE_MINI_PILL_ROUTES.includes(
      // @ts-expect-error
      currentPagedDeparture.route,
    );
    const pillCenterOffset = currentPillIsWide ? 64.5 : 30; // px
    const totalPillSpaceWidth = selectedRightOffset * pillSpace;
    const totalPillWidth =
      numWidePillsToTheRight * widePillWidth +
      numNormalPillsToTheRight * normalPillWidth;
    const translateWidth =
      totalPillSpaceWidth + totalPillWidth + pillCenterOffset;

    const caretBaseClass = "later-departure__route-pill-caret";
    const beforeCaretClass = classWithModifier(caretBaseClass, "before");
    const afterCaretClass = classWithModifier(caretBaseClass, "after");

    return (
      <div className="later-departure">
        <div className="later-departure__header">
          <div className="later-departure__header-title">Later Departures</div>
          <div
            className={classWithModifier(
              "later-departure__header-route-list",
              sizeModifier,
            )}
          >
            {this.props.departures.map((departure, i) => {
              const rightOffset = this.props.pageCount - (i + 1);
              return (
                // @ts-expect-error
                <React.Fragment key={departure.id}>
                  {rightOffset === 0 && (
                    <div
                      className={beforeCaretClass}
                      style={{
                        transform: `translateX(-${translateWidth}px)`,
                      }}
                    ></div>
                  )}
                  <PagedDepartureRoutePill
                    // @ts-expect-error
                    route={departure.route}
                    // @ts-expect-error
                    routeId={departure.route_id}
                    selected={i === this.state.currentPageNumber}
                  />
                  {rightOffset === 0 && (
                    <div
                      className={afterCaretClass}
                      style={{
                        transform: `translateX(-${translateWidth}px)`,
                      }}
                    ></div>
                  )}
                </React.Fragment>
              );
            })}
          </div>
        </div>
        <Departure
          // @ts-expect-error
          {...camelizeDepartureObject(currentPagedDeparture)}
          // @ts-expect-error
          currentTimeString={this.props.currentTimeString}
          overhead={this.props.overhead}
          groupStart={true}
          groupEnd={true}
        />
      </div>
    );
  }
}

interface DepartureListProps {
  departures: any[];
  currentTimeString: string;
  isAnimated: boolean;
  overhead: boolean;
}

const isGroupStart = (departures, i) => {
  if (i === 0) {
    return true;
  }

  const departure = departures[i];
  const prev = departures[i - 1];
  return (
    departure.destination !== prev.destination || departure.route !== prev.route
  );
};

const isGroupEnd = (departures, i) => {
  if (i === departures.length - 1) {
    return true;
  }

  const departure = departures[i];
  const next = departures[i + 1];
  return (
    departure.destination !== next.destination || departure.route !== next.route
  );
};

const DepartureList = ({
  departures,
  currentTimeString,
  isAnimated,
  overhead,
}: DepartureListProps): JSX.Element => {
  if (isAnimated) {
    return (
      <TransitionGroup component={null}>
        {departures.map((departure, i) => {
          const isImminent = isArrivingOrBoarding(departure, currentTimeString);

          const transitionProps = isImminent
            ? {
                timeout: { exit: 400 },
                classNames: classWithModifier("departure-animated", "arr-brd"),
                enter: false,
                exit: true,
              }
            : {
                timeout: { enter: 400 },
                classNames: classWithModifier("departure-animated", "normal"),
                enter: true,
                exit: false,
              };

          return (
            <CSSTransition {...transitionProps} key={departure.id}>
              <Departure
                {...camelizeDepartureObject(departure)}
                currentTimeString={currentTimeString}
                overhead={overhead}
                groupStart={isGroupStart(departures, i)}
                groupEnd={isGroupEnd(departures, i)}
              />
            </CSSTransition>
          );
        })}
      </TransitionGroup>
    );
  } else {
    return (
      <>
        {departures.map((departure, i) => (
          <Departure
            {...camelizeDepartureObject(departure)}
            currentTimeString={currentTimeString}
            overhead={overhead}
            groupStart={isGroupStart(departures, i)}
            groupEnd={isGroupEnd(departures, i)}
            key={departure.id}
          />
        ))}
      </>
    );
  }
};

const HeadwayDepartureList = ({
  pill,
  headsigns,
  rangeLow,
  rangeHigh,
}): JSX.Element => {
  return (
    <>
      {headsigns.map((headsign) => (
        <HeadwayDeparture
          pill={pill}
          headsign={headsign}
          rangeLow={rangeLow}
          rangeHigh={rangeHigh}
          key={headsign}
        />
      ))}
    </>
  );
};

const MAX_PAGE_COUNT = 5;
const MIN_PAGE_COUNT = 3;

const getPageCount = (departures, numRows) => {
  const excessDepartures = departures.length - numRows + 1;
  const unadjustedPageCount = Math.min(excessDepartures, MAX_PAGE_COUNT);

  // Reduce the number of pages if needed to make room for slashed routes
  // which require wider mini-pills.
  const startIndex = numRows - 1;
  const widePillCount = departures
    .slice(startIndex, startIndex + unadjustedPageCount)
    .filter(({ route }) => WIDE_MINI_PILL_ROUTES.includes(route)).length;
  return unadjustedPageCount - widePillCount;
};

interface PagedSectionProps {
  departures: object[];
  numRows: number;
  arrow: Direction | null;
  sectionHeaders: "normal" | "vertical" | "none";
  name: string | null;
  pill: string;
  overhead: boolean;
  isAnimated: boolean;
  currentTimeString: string;
}

const PagedSection = ({
  departures,
  numRows,
  arrow,
  sectionHeaders,
  name,
  pill,
  overhead,
  isAnimated,
  currentTimeString,
  // @ts-expect-error
  disabled,
}: PagedSectionProps): JSX.Element => {
  const pageCount = getPageCount(departures, numRows);
  const showPagedDeparture = pageCount >= MIN_PAGE_COUNT;
  const staticDepartures = showPagedDeparture
    ? departures.slice(0, numRows - 1)
    : departures;

  const frameProps = {
    sectionHeaders,
    name,
    arrow: sectionHeaders === "normal" ? arrow : null,
    overhead,
    departuresLength: staticDepartures.length,
  };

  if (staticDepartures.length === 0) {
    return (
      <SectionFrame {...frameProps}>
        {disabled ? (
          <NoDataMessage pill={pill} />
        ) : (
          // @ts-expect-error
          <NoDeparturesMessage pill={pill} />
        )}
      </SectionFrame>
    );
  }

  let pagedDepartures;
  if (showPagedDeparture) {
    const startIndex = numRows - 1;
    pagedDepartures = departures.slice(startIndex, startIndex + pageCount);
  }

  return (
    <SectionFrame {...frameProps}>
      <DepartureList
        departures={staticDepartures}
        currentTimeString={currentTimeString}
        overhead={overhead}
        isAnimated={isAnimated}
      />
      {showPagedDeparture && (
        <PagedDeparture
          pageCount={pageCount}
          departures={pagedDepartures}
          overhead={overhead}
        />
      )}
    </SectionFrame>
  );
};

const Section = ({
  name,
  arrow,
  departures,
  sectionHeaders,
  currentTimeString,
  numRows,
  overhead,
  isAnimated,
  pill,
  headway: { active, headsigns, range_low: rangeLow, range_high: rangeHigh },
  disabled,
  stationName,
}): JSX.Element => {
  departures = departures.slice(0, numRows);

  if (sectionHeaders !== "normal") {
    arrow = null;
  }

  const frameProps = {
    sectionHeaders,
    name,
    arrow,
    overhead,
    departuresLength: departures.length,
  };

  if (departures.length === 0) {
    return (
      <SectionFrame {...frameProps}>
        {disabled ? (
          <NoDataMessage pill={pill} />
        ) : (
          <NoDeparturesMessage pill={pill} stationName={stationName} />
        )}
      </SectionFrame>
    );
  }

  if (active) {
    return (
      <SectionFrame {...frameProps}>
        <HeadwayDepartureList
          pill={pill}
          headsigns={headsigns}
          rangeLow={rangeLow}
          rangeHigh={rangeHigh}
        />
      </SectionFrame>
    );
  }

  return (
    <SectionFrame {...frameProps}>
      <DepartureList
        departures={departures}
        currentTimeString={currentTimeString}
        overhead={overhead}
        isAnimated={isAnimated}
      />
    </SectionFrame>
  );
};

export { PagedSection, Section, WIDE_MINI_PILL_ROUTES };

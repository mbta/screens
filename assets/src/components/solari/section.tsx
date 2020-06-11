import React from "react";

import Departure from "Components/solari/departure";
import Arrow, { Direction } from "Components/solari/arrow";
import {
  SectionRoutePill,
  PagedDepartureRoutePill,
} from "Components/solari/route_pill";
import BaseDepartureDestination from "Components/eink/base_departure_destination";
import { classWithModifier } from "Util/util";

const camelizeDepartureObject = ({
  id,
  route,
  destination,
  time,
  route_id: routeId,
  vehicle_status: vehicleStatus,
  alerts,
  stop_type: stopType,
}) => ({
  id,
  route,
  destination,
  time,
  routeId,
  vehicleStatus,
  alerts,
  stopType,
});

const DepartureGroup = ({ departures, currentTimeString }): JSX.Element => {
  const groupModifier = departures.length > 1 ? "multiple-rows" : "single-row";

  return (
    <div className={classWithModifier("departure-group", groupModifier)}>
      {departures.map(
        (
          {
            id,
            route,
            destination,
            time,
            route_id: routeId,
            vehicle_status: vehicleStatus,
            alerts,
            stop_type: stopType,
          },
          i
        ) => {
          return (
            <Departure
              route={i === 0 ? route : null}
              routeId={routeId}
              destination={i === 0 ? destination : null}
              time={time}
              currentTimeString={currentTimeString}
              vehicleStatus={vehicleStatus}
              alerts={i === 0 ? alerts : []}
              stopType={stopType}
              key={id}
            />
          );
        }
      )}
    </div>
  );
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
  children,
}): JSX.Element => {
  const sectionModifier = sectionHeaders === "vertical" ? "vertical" : "normal";
  const sectionClass = classWithModifier("section", sectionModifier);

  return (
    <div className={sectionClass}>
      {sectionHeaders !== null && name !== null && (
        <SectionHeader name={name} arrow={arrow} />
      )}
      <div className="departure-container">{children}</div>
    </div>
  );
};

const NoDeparturesMessage = ({ pill }): JSX.Element => (
  <div className={classWithModifier("departure", "no-via")}>
    <SectionRoutePill pill={pill} />
    <div
      className={classWithModifier(
        "departure-destination",
        "no-departures-placeholder"
      )}
    >
      <BaseDepartureDestination destination="No departures currently available" />
    </div>
  </div>
);

interface PagedDepartureProps {
  pageCount: number;
  departures: object[];
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
    const refreshMs = this.pageDuration();
    if (refreshMs !== null) {
      this.interval = window.setInterval(
        this.updatePaging.bind(this),
        refreshMs
      );
    }
  }

  componentWillUnmount() {
    if (this.interval) {
      clearInterval(this.interval);
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

    return (
      <div className="later-departure">
        <div className="later-departure__header">
          <div className="later-departure__header-title">Later Departures</div>
          <div
            className={classWithModifier(
              "later-departure__header-route-list",
              sizeModifier
            )}
          >
            {this.props.departures.map((departure, i) => (
              <PagedDepartureRoutePill
                route={departure.route}
                routeId={departure.route_id}
                selected={i === this.state.currentPageNumber}
                key={departure.id}
              />
            ))}
          </div>
        </div>
        <Departure
          {...camelizeDepartureObject(currentPagedDeparture)}
          currentTimeString={this.props.currentTimeString}
        />
      </div>
    );
  }
}

const MAX_PAGE_COUNT = 5;
const MIN_PAGE_COUNT = 3;

interface PagedSectionProps {
  departures: object[];
  numRows: number;
  arrow: Direction | null;
  sectionHeaders: "normal" | "vertical" | null;
  name: string | null;
  pill: string;
  currentTimeString: string;
}

const PagedSection = ({
  departures,
  numRows,
  arrow,
  sectionHeaders,
  name,
  pill,
  currentTimeString,
}: PagedSectionProps): JSX.Element => {
  const excessDepartures = departures.length - numRows + 1;
  const pageCount = Math.min(excessDepartures, MAX_PAGE_COUNT);

  const showPagedDeparture = pageCount >= MIN_PAGE_COUNT;
  const staticDepartures = showPagedDeparture
    ? departures.slice(0, numRows - 1)
    : departures;

  const frameProps = {
    sectionHeaders,
    name,
    arrow: sectionHeaders === "normal" ? arrow : null,
  };

  if (staticDepartures.length === 0) {
    return (
      <SectionFrame {...frameProps}>
        <NoDeparturesMessage pill={pill} />
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
      {staticDepartures.map((departure) => (
        <Departure
          {...camelizeDepartureObject(departure)}
          currentTimeString={currentTimeString}
          key={departure.id}
        />
      ))}
      {showPagedDeparture && (
        <PagedDeparture
          pageCount={pageCount}
          departures={pagedDepartures}
          key={currentTimeString}
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
  pill,
}): JSX.Element => {
  departures = departures.slice(0, numRows);

  if (sectionHeaders !== "normal") {
    arrow = null;
  }

  const frameProps = { sectionHeaders, name, arrow };

  if (departures.length === 0) {
    return (
      <SectionFrame {...frameProps}>
        <NoDeparturesMessage pill={pill} />
      </SectionFrame>
    );
  }

  return (
    <SectionFrame {...frameProps}>
      {departures.map((departure) => (
        <Departure
          {...camelizeDepartureObject(departure)}
          currentTimeString={currentTimeString}
          key={departure.id}
        />
      ))}
    </SectionFrame>
  );
};

export { PagedSection, Section };

import React, { ComponentType, useLayoutEffect, useRef, useState } from "react";
import cx from "classnames";
import _ from "lodash";
import RoutePill, {
  type Pill,
  routePillKey,
} from "Components/v2/departures/route_pill";
import makePersistent, {
  WrappedComponentProps,
} from "Components/v2/persistent_wrapper";
import PagingIndicators from "Components/v2/elevator/paging_indicators";
import useIntervalPaging from "Hooks/v2/use_interval_paging";
import CalendarIcon from "Images/calendar.svg";
import NormalServiceIconBase from "Images/normal-service.svg";
import CalenderAlertIcon from "Images/calendar-alert.svg";
import AccessibilityAlert from "Images/accessibility-alert.svg";
import Logo from "Images/logo.svg";
import { hasOverflowX } from "Util/utils";
import { CLOSURES_PAGING_INTERVAL_MS } from "./constants";

type StationWithClosures = {
  id: string;
  name: string;
  route_icons: Pill[];
  closures: Closure[];
  summary: { text: string; type: "inside" | "other" };
};

type Closure = {
  id: string;
  name: string;
};

type UpcomingClosureInfo = {
  banner: { title: string; postfix: string | null };
  details: { summary: string | null; titles: string[]; postfix: string | null };
};

interface ClosureRowProps {
  station: StationWithClosures;
  isCurrentStation: boolean;
  isFirstRowOnPage: boolean;
}

const NormalServiceIcon = ({ size }: { size: number }) => (
  <NormalServiceIconBase height={size} width={size} fill="#145A06" />
);

const ClosureRow = ({
  station: { id, name, closures, route_icons, summary },
  isCurrentStation,
  isFirstRowOnPage,
}: ClosureRowProps) => {
  return (
    <div
      className={cx("closure-row", {
        "current-station": isCurrentStation,
        "first-row-on-page": isFirstRowOnPage,
      })}
    >
      <div className="closure-row__name-and-pills">
        {isCurrentStation ? (
          <div className="closure-row__station-name">At this station</div>
        ) : (
          <>
            {route_icons.map((route) => (
              <RoutePill pill={route} key={`${routePillKey(route)}-${id}`} />
            ))}
            <div className="closure-row__station-name">{name}</div>
          </>
        )}
      </div>

      {closures.map((closure) => (
        <div
          key={closure.id}
          className={cx("closure-row__elevator-name", {
            "list-item": closures.length > 1,
          })}
        >
          {closure.name} ({closure.id})
        </div>
      ))}

      <div
        className={cx("closure-row__summary", {
          important: summary.type === "other",
        })}
      >
        {summary.text}
      </div>
    </div>
  );
};

interface InStationSummaryProps {
  numClosures: number;
  upcomingClosure?: UpcomingClosureInfo;
}

const InStationSummary = ({
  numClosures,
  upcomingClosure,
}: InStationSummaryProps) => {
  let text: JSX.Element | string;

  if (upcomingClosure) {
    const {
      banner: { title, postfix },
    } = upcomingClosure;

    text = (
      <>
        <b>{title}:</b> This elevator will be closed
        {postfix ? `, ${postfix}` : " for maintenance"}
      </>
    );
  } else if (numClosures === 0) {
    text = "All elevators at this station are currently working";
  } else if (numClosures === 1) {
    text = (
      <>
        <b>This elevator is working.</b> Another elevator at this station is
        down.
      </>
    );
  } else {
    text = (
      <>
        <b>This elevator is working.</b> {numClosures} other elevators at this
        station are down.
      </>
    );
  }

  return (
    <div className="in-station-summary">
      <span className="text">{text}</span>
      <span>
        {upcomingClosure ? (
          <CalendarIcon height={72} width={72} />
        ) : (
          <NormalServiceIcon size={72} />
        )}
      </span>
    </div>
  );
};

const UpcomingClosure = ({
  closure: {
    details: { summary, titles, postfix },
  },
}: {
  closure: UpcomingClosureInfo;
}) => {
  const titleRef = useRef<HTMLDivElement>(null);
  const [titleIndex, setTitleIndex] = useState(0);
  const title = titles[titleIndex];

  useLayoutEffect(() => {
    if (titleIndex < titles.length - 1 && hasOverflowX(titleRef))
      setTitleIndex(titleIndex + 1);
  }, [titles]);

  return (
    <div className="upcoming-closure">
      <CalenderAlertIcon height={249} width={249} />
      <div className="upcoming-closure__title" ref={titleRef}>
        {title}:
      </div>
      <div>This elevator will be closed for maintenance.</div>

      <div>
        {summary ?? (
          <>
            Visit <b>mbta.com/elevators</b> for information about alternate
            routes.
          </>
        )}
      </div>

      <div className="upcoming-closure__postfix">{postfix}</div>
    </div>
  );
};

const NoCurrentClosures = ({
  status,
  upcomingClosure,
}: {
  status: ClosuresStatus;
  upcomingClosure?: UpcomingClosureInfo;
}) => {
  const header = [
    "All MBTA elevators are working",
    status === "nearby_redundancy"
      ? ` or have a backup elevator within 20 ${upcomingClosure ? "ft" : "feet"}`
      : "",
    ".",
  ].join("");

  return (
    <>
      {upcomingClosure ? (
        <div className="closures-info">
          <div className="in-station-summary">
            <div>{header}</div>
            <div>
              <NormalServiceIcon size={72} />
            </div>
          </div>
          <UpcomingClosure closure={upcomingClosure} />
        </div>
      ) : (
        <div className="no-closures">
          <NormalServiceIcon size={150} />
          <div className="no-closures__header">{header}</div>
          <div className="divider" />
          <div className="no-closures__text">
            For info on elevator outages and alternate paths:
            <br />
            <b>mbta.com/elevators</b>
            <br />
            or call the elevator hotline:
            <br />
            <b>617-222-2828</b>
          </div>
          <Logo height={124} width={124} />
        </div>
      )}
    </>
  );
};

const sortStations = (
  stations: StationWithClosures[],
  thisStationId: string,
): StationWithClosures[] =>
  [...stations].sort((a, b) => {
    const aInStation = a.id === thisStationId;
    const bInStation = b.id === thisStationId;

    // Sort all in-station closures above other closures. Within each of those
    // groups, sort by station name.
    if (aInStation && !bInStation) {
      return -1;
    } else if (!aInStation && bInStation) {
      return 1;
    } else {
      return a.name.localeCompare(b.name);
    }
  });

type ClosuresStatus = "no_closures" | "nearby_redundancy";

interface Props extends WrappedComponentProps {
  id: string;
  stations_with_closures: StationWithClosures[] | ClosuresStatus;
  station_id: string;
  upcoming_closure?: UpcomingClosureInfo;
}

const Closures = ({
  stations_with_closures: stations,
  station_id: stationId,
  upcoming_closure: upcomingClosure,
  updateVisibleData,
}: Props) => {
  const numClosuresInStation =
    typeof stations === "string"
      ? 0
      : stations.filter((s) => s.id === stationId).flatMap((s) => s.closures)
          .length;

  const listRef = useRef<HTMLDivElement>(null);

  // Number of rows on each page index of the closure list (not counting the
  // page for an upcoming closure, if there is one).
  const [pageRowCounts, setPageRowCounts] = useState<number[]>([]);

  // Let the browser lay out the closures into flexbox columns (pages) for us,
  // then look at their distinct `offsetLeft` values to determine how many pages
  // we have and how many items are on each.
  useLayoutEffect(() => {
    if (!listRef.current) return;

    const rowCounts = Object.values(
      _.countBy(
        listRef.current.children,
        (child) => (child as HTMLElement).offsetLeft,
      ),
    );

    setPageRowCounts(rowCounts);
  }, [stations]);

  const numListPages = Object.keys(pageRowCounts).length;
  const numPages = upcomingClosure ? numListPages + 1 : numListPages;

  const pageIndex = useIntervalPaging({
    numPages,
    intervalMs: CLOSURES_PAGING_INTERVAL_MS,
    updateVisibleData,
  });

  const isUpcomingClosurePage = upcomingClosure && pageIndex == 0;

  // The current page within the pages of the closure list. Note when the
  // current page is the upcoming closure page, this is -1, which correctly
  // positions the closure list entirely off-screen (it must always be rendered
  // somewhere, so we know how many pages there are for the page indicators).
  const listPageIndex = upcomingClosure ? pageIndex - 1 : pageIndex;

  const listOffsetStyle = {
    "--closure-list-offset": listPageIndex,
  } as React.CSSProperties;

  const numRowsOffPage = pageRowCounts
    .filter((_, index) => index != listPageIndex)
    .reduce((a, b) => a + b, 0);

  // Determine the index of the first row on each page of the closure list, for
  // styling purposes. Each page's first index is the sum of row counts for all
  // preceding pages.
  const firstRowIndices = pageRowCounts.map((_rowCount, pageNum, rowCounts) =>
    rowCounts.slice(0, pageNum).reduce((a, b) => a + b, 0),
  );

  return (
    <div className="elevator-closures">
      {stations === "no_closures" || stations === "nearby_redundancy" ? (
        <NoCurrentClosures
          status={stations}
          upcomingClosure={upcomingClosure}
        />
      ) : (
        <>
          <InStationSummary
            numClosures={numClosuresInStation}
            upcomingClosure={
              isUpcomingClosurePage ? undefined : upcomingClosure
            }
          />

          <div className="closures-info">
            {isUpcomingClosurePage ? (
              <UpcomingClosure closure={upcomingClosure} />
            ) : (
              <div className="header-container">
                <div className="header">
                  <div className="header__title">MBTA Elevator Closures</div>
                  <div>
                    <AccessibilityAlert height={128} width={155} />
                  </div>
                </div>
              </div>
            )}

            <div className="closure-list-container">
              {
                <div
                  className="closure-list"
                  ref={listRef}
                  style={listOffsetStyle}
                >
                  {sortStations(stations, stationId).map((station, index) => (
                    <ClosureRow
                      isCurrentStation={station.id == stationId}
                      isFirstRowOnPage={firstRowIndices.includes(index)}
                      key={station.id}
                      station={station}
                    />
                  ))}
                </div>
              }
            </div>
          </div>
        </>
      )}
      {numPages > 1 && (
        <div className="paging-info-container">
          {!isUpcomingClosurePage && numRowsOffPage > 0 && (
            <div className="more-elevators-text">
              +{numRowsOffPage} more elevator{numRowsOffPage !== 1 ? "s" : ""}
            </div>
          )}
          <PagingIndicators numPages={numPages} pageIndex={pageIndex} />
        </div>
      )}
    </div>
  );
};

export default makePersistent(Closures as ComponentType<WrappedComponentProps>);

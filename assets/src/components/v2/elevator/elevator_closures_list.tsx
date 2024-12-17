import React, { ComponentType, useLayoutEffect, useRef, useState } from "react";
import cx from "classnames";
import _ from "lodash";
import RoutePill, { routePillKey } from "Components/v2/departures/route_pill";
import makePersistent, {
  WrappedComponentProps,
} from "Components/v2/persistent_wrapper";
import PagingIndicators from "Components/v2/elevator/paging_indicators";
import {
  type StationWithClosures,
  type Closure,
} from "Components/v2/elevator/types";
import useClientPaging from "Hooks/v2/use_client_paging";
import NormalService from "Images/svgr_bundled/normal-service.svg";
import AccessibilityAlert from "Images/svgr_bundled/accessibility-alert.svg";

interface ClosureRowProps {
  station: StationWithClosures;
  isCurrentStation: boolean;
}

const ClosureRow = ({
  station: { id, name, closures, route_icons },
  isCurrentStation,
}: ClosureRowProps) => {
  return (
    <div className={cx("closure-row", { "current-station": isCurrentStation })}>
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
          {closure.elevator_name} ({closure.elevator_id})
        </div>
      ))}
    </div>
  );
};

interface InStationSummaryProps {
  closures: Closure[];
}

const InStationSummary = ({ closures }: InStationSummaryProps) => {
  let text;
  if (closures.length === 0) {
    text = "All elevators at this station are currently working";
  } else if (closures.length === 1) {
    text = (
      <>
        <b>This elevator is working.</b> Another elevator at this station is
        down.
      </>
    );
  } else {
    text = (
      <>
        <b>This elevator is working.</b> {closures.length} other elevators at
        this station are down.
      </>
    );
  }

  return (
    <>
      <div className="in-station-summary">
        <span className="text">{text}</span>
        <span>
          <NormalService height={72} width={72} fill="#145A06" />
        </span>
      </div>
    </>
  );
};

interface OutsideClosureListProps extends WrappedComponentProps {
  stations: StationWithClosures[];
  stationId: string;
}

const OutsideClosureList = ({
  stations,
  stationId,
  lastUpdate,
  onFinish,
}: OutsideClosureListProps) => {
  const ref = useRef<HTMLDivElement>(null);

  const sortedStations = [...stations].sort((a, b) => {
    const aInStation = a.id === stationId;
    const bInStation = b.id === stationId;

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

  // Each index represents a page number and each value represents the number of
  // rows on the corresponding page index.
  const [rowCounts, setRowCounts] = useState<number[]>([]);

  const numPages = Object.keys(rowCounts).length;
  const pageIndex = useClientPaging({ numPages, onFinish, lastUpdate });

  const numOffsetRows = Object.keys(rowCounts).reduce((acc, key) => {
    if (parseInt(key) === pageIndex) {
      return acc;
    } else {
      return acc + rowCounts[key];
    }
  }, 0);

  useLayoutEffect(() => {
    if (!ref.current) return;

    const offsets = Array.from(ref.current.children).map((closure) => {
      return (closure as HTMLDivElement).offsetLeft;
    });

    const rowCounts: number[] = [];

    _.uniq(offsets).forEach((uo) => {
      rowCounts.push(offsets.filter((o) => o === uo).length);
    });

    setRowCounts(rowCounts);
  }, [stations]);

  return (
    <div className="closures-list">
      <div className="header-container">
        <div className="header">
          <div className="header__title">MBTA Elevator Closures</div>
          <div>
            <AccessibilityAlert height={128} width={155} />
          </div>
        </div>
      </div>

      <div className="closure-list-container">
        {
          <div
            className="closure-list"
            style={
              {
                "--closure-list-offset": pageIndex,
              } as React.CSSProperties
            }
            ref={ref}
          >
            {sortedStations.map((station) => (
              <ClosureRow
                station={station}
                isCurrentStation={station.id == stationId}
                key={station.id}
              />
            ))}
          </div>
        }
      </div>

      {numPages > 1 && (
        <div className="paging-info-container">
          <div className="more-elevators-text">
            +{numOffsetRows} more elevators
          </div>
          <PagingIndicators numPages={numPages} pageIndex={pageIndex} />
        </div>
      )}
    </div>
  );
};

interface Props extends WrappedComponentProps {
  id: string;
  stations_with_closures: StationWithClosures[];
  station_id: string;
}

const ElevatorClosuresList = ({
  stations_with_closures: stations,
  station_id: stationId,
  lastUpdate,
  onFinish,
}: Props) => {
  return (
    <div className="elevator-closures-list">
      <InStationSummary
        closures={stations
          .filter((s) => s.id === stationId)
          .flatMap((s) => s.closures)}
      />
      <OutsideClosureList
        stations={stations}
        stationId={stationId}
        lastUpdate={lastUpdate}
        onFinish={onFinish}
      />
    </div>
  );
};

export default makePersistent(
  ElevatorClosuresList as ComponentType<WrappedComponentProps>,
);

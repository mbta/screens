import React, { ComponentType, useLayoutEffect, useRef, useState } from "react";
import cx from "classnames";
import NormalService from "Images/svgr_bundled/normal-service.svg";
import AccessibilityAlert from "Images/svgr_bundled/accessibility-alert.svg";
import PagingDotUnselected from "Images/svgr_bundled/paging_dot_unselected.svg";
import PagingDotSelected from "Images/svgr_bundled/paging_dot_selected.svg";
import makePersistent, { WrappedComponentProps } from "../persistent_wrapper";
import RoutePill, { routePillKey, type Pill } from "../departures/route_pill";
import _ from "lodash";
import useClientPaging from "Hooks/v2/use_client_paging";

type StationWithClosures = {
  id: string;
  name: string;
  route_icons: Pill[];
  closures: ElevatorClosure[];
};

type ElevatorClosure = {
  id: string;
  elevator_name: string;
  elevator_id: string;
  description: string;
  header_text: string;
};

interface ClosureRowProps {
  station: StationWithClosures;
}

const ClosureRow = ({ station }: ClosureRowProps) => {
  const { name, closures, route_icons, id } = station;

  return (
    <div className="closure-row">
      <div className="closure-row__name-and-pills">
        {route_icons.map((route) => (
          <RoutePill pill={route} key={`${routePillKey(route)}-${id}`} />
        ))}
        <div className="closure-row__station-name">{name}</div>
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
      <hr className="thin" />
    </div>
  );
};

interface InStationSummaryProps {
  closures: ElevatorClosure[];
}

const InStationSummary = ({ closures }: InStationSummaryProps) => {
  const summaryText = closures.length
    ? ""
    : "All elevators at this station are currently working";

  return (
    <>
      <div className="in-station-summary">
        <span className="text">{summaryText}</span>
        <span>
          <NormalService height={72} width={72} fill="#145A06" />
        </span>
      </div>
      <hr className="thick" />
    </>
  );
};

interface OutsideClosureListProps extends WrappedComponentProps {
  stations: StationWithClosures[];
  lastUpdate: number | null;
}

const OutsideClosureList = ({
  stations,
  lastUpdate,
  onFinish,
}: OutsideClosureListProps) => {
  const ref = useRef<HTMLDivElement>(null);

  // Each index represents a page number and each value represents the number of rows
  // on the corresponding page index.
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

  const getPagingIndicators = (num: number) => {
    const indicators: JSX.Element[] = [];
    for (let i = 0; i < num; i++) {
      const indicator =
        pageIndex === i ? (
          <PagingDotSelected
            className="paging-indicator"
            height={40}
            width={40}
            key={i}
          />
        ) : (
          <PagingDotUnselected
            className="paging-indicator"
            height={28}
            width={28}
            key={i}
          />
        );
      indicators.push(indicator);
    }

    return indicators;
  };

  return (
    <div className="outside-closure-list">
      <div className="header-container">
        <div className="header">
          <div className="header__title">MBTA Elevator Closures</div>
          <div>
            <AccessibilityAlert height={128} width={155} />
          </div>
        </div>
      </div>
      <hr className="thin" />
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
            {stations.map((station) => (
              <ClosureRow station={station} key={station.id} />
            ))}
          </div>
        }
      </div>
      {numPages > 1 && (
        <div className="paging-info-container">
          <div className="more-elevators-text">
            +{numOffsetRows} more elevators
          </div>
          <div className="paging-indicators">
            {getPagingIndicators(numPages)}
          </div>
        </div>
      )}
    </div>
  );
};

interface Props extends WrappedComponentProps {
  id: string;
  in_station_closures: ElevatorClosure[];
  other_stations_with_closures: StationWithClosures[];
}

const ElevatorClosures: React.ComponentType<Props> = ({
  other_stations_with_closures: otherStationsWithClosures,
  in_station_closures: inStationClosures,
  lastUpdate,
  onFinish,
}: Props) => {
  return (
    <div className="elevator-closures">
      <InStationSummary closures={inStationClosures} />
      <OutsideClosureList
        stations={otherStationsWithClosures}
        lastUpdate={lastUpdate}
        onFinish={onFinish}
      />
    </div>
  );
};

export default makePersistent(
  ElevatorClosures as ComponentType<WrappedComponentProps>,
);

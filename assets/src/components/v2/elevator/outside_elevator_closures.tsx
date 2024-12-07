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

const InStationSummary = () => {
  return (
    <>
      <div className="in-station-summary">
        <span className="text">
          All elevators at this station are currently working
        </span>
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

  return (
    <div className="outside-closure-list">
      <div className="header-container">
        <div className="header">
          <div className="header__title">MBTA Elevator Closures</div>
          <div>
            <AccessibilityAlert height={128} width={155} />
          </div>
        </div>
        <hr className="thin" />
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
          <PagingIndicators numPages={numPages} pageIndex={pageIndex} />
        </div>
      )}
    </div>
  );
};

interface Props extends WrappedComponentProps {
  id: string;
  in_station_closures: Closure[];
  other_stations_with_closures: StationWithClosures[];
}

const OutsideElevatorClosures = ({
  other_stations_with_closures: stations,
  lastUpdate,
  onFinish,
}: Props) => {
  return (
    <div className="outside-elevator-closures">
      <InStationSummary />
      <OutsideClosureList
        stations={stations}
        lastUpdate={lastUpdate}
        onFinish={onFinish}
      />
    </div>
  );
};

export default makePersistent(
  OutsideElevatorClosures as ComponentType<WrappedComponentProps>,
);

import React, { ComponentType, useLayoutEffect, useRef, useState } from "react";
import cx from "classnames";
import _ from "lodash";
import NormalService from "Images/svgr_bundled/normal-service.svg";
import AccessibilityAlert from "Images/svgr_bundled/accessibility-alert.svg";
import PagingDotUnselected from "Images/svgr_bundled/paging_dot_unselected.svg";
import PagingDotSelected from "Images/svgr_bundled/paging_dot_selected.svg";
import NoService from "Images/svgr_bundled/no-service-black.svg";
import ElevatorWayfinding from "Images/svgr_bundled/elevator-wayfinding.svg";
import Arrow from "Images/svgr_bundled/arrow-90.svg";
import IsaNegative from "Images/svgr_bundled/isa-negative.svg";
import makePersistent, { WrappedComponentProps } from "../persistent_wrapper";
import RoutePill, { routePillKey, type Pill } from "../departures/route_pill";
import useClientPaging from "Hooks/v2/use_client_paging";
import useTextResizer from "Hooks/v2/use_text_resizer";

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

type ArrowDirection = "n" | "e" | "s" | "w";

interface PagingIndicatorsProps {
  numPages: number;
  pageIndex: number;
}

const PagingIndicators = ({ numPages, pageIndex }: PagingIndicatorsProps) => {
  const indicators: JSX.Element[] = [];
  for (let i = 0; i < numPages; i++) {
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

  return <div className="paging-indicators">{indicators}</div>;
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

interface OutsideClosuresViewProps extends OutsideClosureListProps {}

const OutsideClosuresView = ({
  stations,
  lastUpdate,
  onFinish,
}: OutsideClosuresViewProps) => {
  return (
    <div className="outside-closures-view">
      <InStationSummary />
      <OutsideClosureList
        stations={stations}
        lastUpdate={lastUpdate}
        onFinish={onFinish}
      />
    </div>
  );
};

interface CurrentElevatorClosedViewProps extends WrappedComponentProps {
  closure: ElevatorClosure;
  alternateDirectionText: string;
  accessiblePathDirectionArrow: ArrowDirection;
  accessiblePathImageUrl: string;
}

const CurrentElevatorClosedView = ({
  alternateDirectionText,
  accessiblePathDirectionArrow,
  onFinish,
  lastUpdate,
}: CurrentElevatorClosedViewProps) => {
  const pageIndex = useClientPaging({ numPages: 2, onFinish, lastUpdate });
  const { ref, size } = useTextResizer({
    sizes: ["small", "medium", "large"],
    maxHeight: 746,
    resetDependencies: [alternateDirectionText],
  });

  return (
    <div className="current-elevator-closed-view">
      <div className="shape"></div>
      <div className="header">
        <div className="icons">
          <NoService className="no-service-icon" height={126} width={126} />
          <ElevatorWayfinding />
        </div>
        <div className="closed-text">Closed</div>
        <div className="subheading">Until further notice</div>
      </div>
      <hr className="thin" />
      <div className="accessible-path-container">
        <div className="subheading-container">
          <div className="subheading">Accessible Path</div>
          <div>
            <IsaNegative width={100} height={100} />
            <Arrow
              width={100}
              height={100}
              className={cx("arrow", accessiblePathDirectionArrow)}
            />
          </div>
        </div>
        <div ref={ref} className={cx("alternate-direction-text", size)}>
          {alternateDirectionText}
        </div>
      </div>
      <PagingIndicators numPages={2} pageIndex={pageIndex} />
    </div>
  );
};

interface Props extends WrappedComponentProps {
  id: string;
  in_station_closures: ElevatorClosure[];
  other_stations_with_closures: StationWithClosures[];
  alternate_direction_text: string;
  accessible_path_direction_arrow: ArrowDirection;
  accessible_path_image_url: string;
}

const ElevatorClosures: React.ComponentType<Props> = ({
  id,
  other_stations_with_closures: otherStationsWithClosures,
  in_station_closures: inStationClosures,
  alternate_direction_text: alternateDirectionText,
  accessible_path_direction_arrow: accessiblePathDirectionArrow,
  accessible_path_image_url: accessiblePathImageUrl,
  lastUpdate,
  onFinish,
}: Props) => {
  const currentElevatorClosure = inStationClosures.find(
    (c) => c.elevator_id === id,
  );

  return (
    <div className="elevator-closures">
      {currentElevatorClosure ? (
        <CurrentElevatorClosedView
          closure={currentElevatorClosure}
          alternateDirectionText={alternateDirectionText}
          accessiblePathDirectionArrow={accessiblePathDirectionArrow}
          accessiblePathImageUrl={accessiblePathImageUrl}
          onFinish={onFinish}
          lastUpdate={lastUpdate}
        />
      ) : (
        <OutsideClosuresView
          stations={otherStationsWithClosures}
          lastUpdate={lastUpdate}
          onFinish={onFinish}
        />
      )}
    </div>
  );
};

export default makePersistent(
  ElevatorClosures as ComponentType<WrappedComponentProps>,
);

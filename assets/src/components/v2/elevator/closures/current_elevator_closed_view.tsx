import React from "react";
import cx from "classnames";
import Arrow, { Direction } from "Components/v2/arrow";
import { WrappedComponentProps } from "Components/v2/persistent_wrapper";
import PagingIndicators from "Components/v2/elevator/closures/paging_indicators";
import { type ElevatorClosure } from "Components/v2/elevator/elevator_closures";
import useClientPaging from "Hooks/v2/use_client_paging";
import useTextResizer from "Hooks/v2/use_text_resizer";
import CurrentLocationMarker from "Images/svgr_bundled/current-location-marker.svg";
import CurrentLocationBackground from "Images/svgr_bundled/current-location-background.svg";
import NoService from "Images/svgr_bundled/no-service-black.svg";
import ElevatorWayfinding from "Images/svgr_bundled/elevator-wayfinding.svg";
import IsaNegative from "Images/svgr_bundled/isa-negative.svg";

export type Coordinates = {
  x: number;
  y: number;
};

const PulsatingDot = ({ x, y }: Coordinates) => {
  return (
    <div className="marker-container" style={{ top: x, left: y }}>
      <CurrentLocationBackground className="marker-background" />
      <CurrentLocationMarker className="marker" />
    </div>
  );
};

interface CurrentElevatorClosedViewProps extends WrappedComponentProps {
  closure: ElevatorClosure;
  alternateDirectionText: string;
  accessiblePathDirectionArrow: Direction;
  accessiblePathImageUrl: string | null;
  accessiblePathImageHereCoordinates: Coordinates;
}

const CurrentElevatorClosedView = ({
  alternateDirectionText,
  accessiblePathDirectionArrow,
  accessiblePathImageUrl,
  accessiblePathImageHereCoordinates,
  onFinish,
  lastUpdate,
}: CurrentElevatorClosedViewProps) => {
  const numPages = accessiblePathImageUrl ? 2 : 1;
  const pageIndex = useClientPaging({ numPages, onFinish, lastUpdate });
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
            <Arrow direction={accessiblePathDirectionArrow} className="arrow" />
          </div>
        </div>
        {pageIndex === 0 ? (
          <div ref={ref} className={cx("alternate-direction-text", size)}>
            {alternateDirectionText}
          </div>
        ) : (
          <div className="map-container">
            <PulsatingDot
              x={accessiblePathImageHereCoordinates.x}
              y={accessiblePathImageHereCoordinates.y}
            />
            <img className="map" src={accessiblePathImageUrl!} />
          </div>
        )}
      </div>
      {numPages === 2 && (
        <PagingIndicators numPages={numPages} pageIndex={pageIndex} />
      )}
    </div>
  );
};

export default CurrentElevatorClosedView;

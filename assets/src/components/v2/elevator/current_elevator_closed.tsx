import React, { ComponentType, useContext } from "react";
import cx from "classnames";
import Arrow, { Direction } from "Components/v2/arrow";
import makePersistent, {
  WrappedComponentProps,
} from "Components/v2/persistent_wrapper";
import PagingIndicators from "Components/v2/elevator/paging_indicators";
import useTextResizer from "Hooks/v2/use_text_resizer";
import CurrentLocationMarker from "Images/svgr_bundled/current-location-marker.svg";
import CurrentLocationBackground from "Images/svgr_bundled/current-location-background.svg";
import NoService from "Images/svgr_bundled/no-service-black.svg";
import ElevatorWayfinding from "Images/svgr_bundled/elevator-wayfinding.svg";
import IsaNegative from "Images/svgr_bundled/isa-negative.svg";
import usePageAdvancer from "Hooks/v2/use_page_advancer";

type Coordinates = {
  x: number;
  y: number;
};

const PulsatingDot = ({ x, y }: Coordinates) => {
  return (
    <div className="marker-container" style={{ left: x, top: y }}>
      <CurrentLocationBackground className="marker-background" />
      <CurrentLocationMarker className="marker" />
    </div>
  );
};

interface Props extends WrappedComponentProps {
  alternate_direction_text: string;
  accessible_path_direction_arrow: Direction | null;
  accessible_path_image_url: string | null;
  accessible_path_image_here_coordinates: Coordinates;
}

const CurrentElevatorClosed = ({
  alternate_direction_text: alternateDirectionText,
  accessible_path_direction_arrow: accessiblePathDirectionArrow,
  accessible_path_image_url: accessiblePathImageUrl,
  accessible_path_image_here_coordinates: accessiblePathImageHereCoordinates,
  onFinish,
}: Props) => {
  const numPages = accessiblePathImageUrl ? 2 : 1;
  const { pageIndex } = usePageAdvancer({
    numPages,
    cycleInterval: 12000, // 12 seconds
    advanceOnDataRefresh: false,
    onFinish,
  });

  const { ref, size } = useTextResizer({
    sizes: ["small", "medium", "large"],
    maxHeight: 746,
    resetDependencies: [alternateDirectionText],
  });

  return (
    <div className="current-elevator-closed">
      <div className="notch"></div>
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
            {accessiblePathDirectionArrow ? (
              <Arrow
                direction={accessiblePathDirectionArrow}
                className="arrow"
              />
            ) : null}
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

export default makePersistent(
  CurrentElevatorClosed as ComponentType<WrappedComponentProps>,
);

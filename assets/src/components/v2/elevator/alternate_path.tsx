import type { ComponentType } from "react";
import cx from "classnames";
import Arrow, { Direction, LineWeight } from "Components/v2/arrow";
import makePersistent, {
  WrappedComponentProps,
} from "Components/v2/persistent_wrapper";
import PagingIndicators from "Components/v2/elevator/paging_indicators";
import useIntervalPaging from "Hooks/v2/use_interval_paging";
import useAutoSize from "Hooks/use_auto_size";
import CurrentLocationMarker from "Images/current-location-marker.svg";
import CurrentLocationBackground from "Images/current-location-background.svg";
import NoService from "Images/no-service-black.svg";
import ElevatorWayfinding from "Images/elevator-wayfinding.svg";
import IsaNegative from "Images/isa-negative.svg";
import { ALTERNATE_PATH_PAGING_INTERVAL_MS } from "./constants";

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

const AlternatePath = ({
  alternate_direction_text: alternateDirectionText,
  accessible_path_direction_arrow: accessiblePathDirectionArrow,
  accessible_path_image_url: accessiblePathImageUrl,
  accessible_path_image_here_coordinates: accessiblePathImageHereCoordinates,
  updateVisibleData,
}: Props) => {
  const numPages = accessiblePathImageUrl ? 2 : 1;
  const pageIndex = useIntervalPaging({
    numPages,
    intervalMs: ALTERNATE_PATH_PAGING_INTERVAL_MS,
    updateVisibleData,
  });

  const { ref: textRef, step: textSize } = useAutoSize(
    ["large", "medium", "small"],
    alternateDirectionText,
  );

  return (
    <div className="elevator-alternate-path">
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
                lineWeight={LineWeight.THIN}
              />
            ) : null}
          </div>
        </div>
        {pageIndex === 0 ? (
          <div
            className={cx("alternate-direction-text", textSize)}
            ref={textRef}
          >
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
  AlternatePath as ComponentType<WrappedComponentProps>,
);

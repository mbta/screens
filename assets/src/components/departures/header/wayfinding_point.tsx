import type { ComponentType } from "react";
import WayfindingDirectionBeam from "Images/wayfinding_direction_beam.svg";

import { classWithModifier } from "Util/utils";

type WayfindingPointProps = {
  x_position: number;
  y_position: number;
  beam_angle: number | null;
};

const WayfindingPoint: ComponentType<WayfindingPointProps> = ({
  x_position: xPosition,
  y_position: yPosition,
  beam_angle: degrees,
}) => {
  const showDirectionBeam = degrees !== null;
  return (
    <div
      className="wayfinding-point-container"
      style={{ left: xPosition, top: yPosition }}
    >
      {showDirectionBeam && (
        <WayfindingDirectionBeam
          className="direction-beam"
          style={{
            transform: `rotate(${degrees}deg)`,
          }}
        ></WayfindingDirectionBeam>
      )}
      <div
        className={classWithModifier(
          "wayfinding-point",
          showDirectionBeam ? "" : "animated",
        )}
      >
        <div
          className={classWithModifier(
            "inner-dot",
            showDirectionBeam ? "animated" : "",
          )}
        ></div>
      </div>
    </div>
  );
};

export type { WayfindingPointProps };
export default WayfindingPoint;

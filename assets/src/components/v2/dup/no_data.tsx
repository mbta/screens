import React, { ComponentType } from "react";
import { imagePath } from "Util/util";
import LinkArrow from "../bundled_svg/link_arrow";
import NormalHeader from "./normal_header";
import { useStationName } from "Hooks/outfront";

// Fix station name tags without rider-facing names
export const REPLACEMENTS = {
  WTC: "World Trade Center",
  Malden: "Malden Center",
} as { [key: string]: string };

const NoData: ComponentType = () => {
  let stationName = useStationName() || "Transit information";
  stationName = REPLACEMENTS[stationName] || stationName;

  return (
    <div className="no-data__container">
      <NormalHeader text={stationName} />

      <div className="no-data__body">
        <div className="no-data__icon-container">
          <img
            className="no-data__icon-image"
            src={imagePath("live-data-none.svg")}
          />
        </div>
        <div className="no-data__message">
          Live updates are temporarily unavailable
        </div>
      </div>

      <div className="no-data__link">
        <div className="no-data__link-arrow">
          <LinkArrow width={375} colorHex="#a2a3a3" />
        </div>
        <div className="no-data__link-text">mbta.com/schedules</div>
      </div>
    </div>
  );
};

export default NoData;

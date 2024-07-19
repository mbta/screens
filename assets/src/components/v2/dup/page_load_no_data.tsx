import React, { ComponentType } from "react";
import LinkArrow from "../bundled_svg/link_arrow";
import Loading from "Images/svgr_bundled/loading.svg";
import NormalHeader from "./normal_header";
import { REPLACEMENTS } from "./no_data";
import { useStationName } from "Hooks/outfront";

const PageLoadNoData: ComponentType = () => {
  let stationName = useStationName() || "Transit information";
  stationName = REPLACEMENTS[stationName] || stationName;

  return (
    <div className="loading__container">
      <NormalHeader text={stationName} />
      <div className="loading__body">
        <div className="loading__icon-container">
          <Loading width="128" height="128" color="#171F26" />
        </div>
        <div className="loading__heading">Loading...</div>
        <div className="loading__sub-heading">
          This should only take a moment.
        </div>
      </div>
      <div className="loading__link">
        <div className="loading__link-arrow">
          <LinkArrow width={375} colorHex="#a2a3a3" />
        </div>
        <div className="loading__link-text">mbta.com/schedules</div>
      </div>
    </div>
  );
};

export default PageLoadNoData;

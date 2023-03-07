import useOutfrontStation from "Hooks/use_outfront_station";
import React, { ComponentType } from "react";
import LinkArrow from "../bundled_svg/link_arrow";
import Loading from "../bundled_svg/loading";
import NormalHeader from "./normal_header";

// Fix station name tags without rider-facing names
const REPLACEMENTS = {
  WTC: "World Trade Center",
  Malden: "Malden Center",
} as {[key:string]: string};

const PageLoadNoData: ComponentType = () => {
  let stationName = useOutfrontStation() || "Transit information";
  stationName = REPLACEMENTS[stationName] || stationName;
  
  return (
    <div className="loading__container">
      <NormalHeader text={stationName} />
      <div className="loading__body">
        <div className="loading__icon-container">
          <Loading colorHex={"#171F26"} />
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
import React from "react";

import CRPill from "Images/svgr_bundled/pills/commuter-rail.svg";
import { getHexColor } from "Util/svg_utils";

const CRDeparturesHeaderNormal = () => {
  return (
    <div className="departures-card__header">
      <CRPill width="523" height="82" color={getHexColor("purple")} />
      <div className="departures-card__header-text">Upcoming departures</div>
    </div>
  );
};

export default CRDeparturesHeaderNormal;

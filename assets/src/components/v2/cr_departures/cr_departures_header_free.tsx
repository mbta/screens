import React from "react";

import CRPill from "../../../../static/images/svgr_bundled/pills/commuter-rail.svg";
import RoutePill from "../departures/route_pill";
import { getHexColor } from "Util/svg_utils";

const CRDeparturesHeaderFree = ({ headerPill }) => {
  return (
    <div className="departures-card__header">
      <CRPill width="523" height="82" color={getHexColor("purple")} />
      <div className="departures-card__header-text">
        <span>Free Commuter Rail during</span>
        <span className="pill-container">
          <RoutePill {...headerPill} />
        </span>
        <span>disruption</span>
      </div>
    </div>
  );
};

export default CRDeparturesHeaderFree;

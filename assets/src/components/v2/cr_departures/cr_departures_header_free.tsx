import React from "react";

import CRPill from "Images/pills/commuter-rail.svg";
import RoutePill from "../departures/route_pill";
import { getHexColor } from "Util/svg_utils";

const CRDeparturesHeaderFree = ({ headerPill }) => {
  return (
    <div className="cr-departures-card__header">
      <CRPill width="523" height="82" color={getHexColor("purple")} />
      <div className="cr-departures-card__header-text">
        <span>Free Commuter Rail during</span>
        <span className="pill-container">
          <RoutePill pill={headerPill} />
        </span>
        <span>disruption</span>
      </div>
    </div>
  );
};

export default CRDeparturesHeaderFree;

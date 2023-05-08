import React from "react";

import Free from "Components/v2/bundled_svg/free";
import { pillPath } from "Util/util";
import RoutePill from "../departures/route_pill";

const CRDeparturesHeader = ({ headerPill }) => {
  return (
    <div className="departures-card__header">
      <img src={pillPath("commuter-rail.svg")}></img>
      <div className="departures-card__header-text">
        <span>Consider Commuter Rail during</span>
        <span className="pill-container">
          <RoutePill {...headerPill} />
        </span>
        <span>delays</span>
      </div>
      <div className="departures-card__sub-header">
        <div>
          <Free className="free-cr" colorHex="#171F26" />
        </div>
        Show any type of CharlieCard or CharlieTicket to ride free of charge
      </div>
    </div>
  );
};

export default CRDeparturesHeader;

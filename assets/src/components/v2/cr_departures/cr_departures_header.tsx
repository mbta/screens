import React from "react";

import Free from "../../../../static/images/svgr_bundled/free.svg";
import CRPill from '../../../../static/images/svgr_bundled/pills/commuter-rail.svg'
import RoutePill from "../departures/route_pill";
import { getHexColor } from "Util/svg_utils";

const CRDeparturesHeader = ({ headerPill }) => {

  return (
    <div className="departures-card__header">
      <CRPill width="523" height="82" color={getHexColor("purple")} />
      <div className="departures-card__header-text">
        <span>Consider Commuter Rail during</span>
        <span className="pill-container">
          <RoutePill {...headerPill} />
        </span>
        <span>delays</span>
      </div>
      <div className="departures-card__sub-header">
        <div>
          <Free width="128" height="128" className="free-cr" color="#171F26" />
        </div>
        Show any type of CharlieCard or CharlieTicket to ride free of charge
      </div>
    </div>
  );
};

export default CRDeparturesHeader;

import React from "react";

import Free from "Components/v2/bundled_svg/free";
import { pillPath } from "Util/util";

const CRDeparturesHeader = () => {
  return (
    <div className="departures-card__header">
      <img src={pillPath("commuter-rail.svg")}></img>
      <div className="departures-card__header-text">
        <span>Consider Commuter Rail during</span>
        <span className="pill-container"><img className="inline-ol-pill" src={pillPath("ol.svg")}></img></span>
        <span>delays</span>
      </div>
      <div className="departures-card__sub-header">
        <div>
          <Free className="free-cr" colorHex="#171F26" />
        </div>
        Show your CharlieCard or CharlieTicket to ride at no charge
      </div>
    </div>
  );
};

export default CRDeparturesHeader;

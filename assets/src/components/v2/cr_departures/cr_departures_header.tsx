import React from "react";

import CRIcon from "Components/v2/bundled_svg/cr_icon";

const CRDeparturesHeader = () => {
  return (
    <div className="departures-card__header">
      <CRIcon className="commuter-rail-icon" colorHex="#d9d6d0" />
      <div className="departures-card__header-text">
        <div className="departures-card__header-text-english">
          Commuter Rail
        </div>
        <div className="departures-card__header-text-spanish">
          Tren de Cercanías
        </div>
      </div>
    </div>
  );
};

export default CRDeparturesHeader;

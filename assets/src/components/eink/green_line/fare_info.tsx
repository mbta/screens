import React from "react";
import { imagePath } from "Util/util";

const FareInfo = (): JSX.Element => {
  return (
    <div className="fares">
      <div className="fares__icon-container">
        <img
          className="fares__icon-image"
          src={imagePath("subway-negative-black.svg")}
        />
      </div>
      <div className="fares__info-container">
        <div className="fares__info-header">Subway one-way</div>
        <div className="fares__info-link">mbta.com/fares/subway-fares</div>
        <div className="fares__info-rows">
          <div className="fares__info-row">
            <span className="fares__info-row-cost">$2.40 </span>
            <span className="fares__info-row-description">CharlieCard </span>
            <span className="fares__info-row-details">
              (1 free local bus transfer within 2 hrs)
            </span>
          </div>
          <div className="fares__info-row">
            <span className="fares__info-row-cost">$2.40 </span>
            <span className="fares__info-row-description">
              CharlieTicket or cash{" "}
            </span>
            <span className="fares__info-row-details">(Limited transfers)</span>
          </div>
        </div>
      </div>
    </div>
  );
};

export default FareInfo;

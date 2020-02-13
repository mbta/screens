import React from "react";

const FareInfo = (): JSX.Element => {
  return (
    <div className="fares">
      <div className="fares__icon-container">
        <img
          className="fares__icon-image"
          src="images/bus-negative-black.svg"
        />
      </div>
      <div className="fares__info-container">
        <div className="fares__info-header">Local bus one-way</div>
        <div className="fares__info-link">More at www.mbta.com/fares</div>
        <div className="fares__info-rows">
          <div className="fares__info-row">
            <span className="fares__info-row-cost">$1.70 </span>
            <span className="fares__info-row-description">CharlieCard </span>
            <span className="fares__info-row-details">
              (1 free transfer to Local Bus)
            </span>
          </div>
          <div className="fares__info-row">
            <span className="fares__info-row-cost">$2.00 </span>
            <span className="fares__info-row-description">
              Cash or CharlieTicket{" "}
            </span>
            <span className="fares__info-row-details">(Limited Transfers)</span>
          </div>
        </div>
      </div>
    </div>
  );
};

export default FareInfo;

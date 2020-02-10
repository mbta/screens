import React from "react";

const FareInfo = (): JSX.Element => {
  return (
    <div className="fare-container">
      <div className="fare-icon-container">
        <img className="fare-icon-image" src="images/bus.svg" />
      </div>
      <div className="fare-info-container">
        <div className="fare-info-header">Local bus one-way</div>
        <div className="fare-info-link">More at www.mbta.com/fares</div>
        <div className="fare-info-rows">
          <div className="fare-info-row">
            <span className="fare-info-row-cost">$1.70 </span>
            <span className="fare-info-row-description">CharlieCard </span>
            <span className="fare-info-row-details">
              (1 free transfer to Local Bus)
            </span>
          </div>
          <div className="fare-info-row">
            <span className="fare-info-row-cost">$2.00 </span>
            <span className="fare-info-row-description">
              Cash or CharlieTicket{" "}
            </span>
            <span className="fare-info-row-details">(Limited Transfers)</span>
          </div>
        </div>
      </div>
    </div>
  );
};

export default FareInfo;

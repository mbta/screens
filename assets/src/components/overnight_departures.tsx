import React from "react";

const OvernightDepartures = (): JSX.Element => {
  return (
    <div className="overnight-departures">
      <div className="overnight-departures__container">
        <div className="overnight-departures__icon">
          <img
            className="overnight-departures__icon-image"
            src="images/overnight.svg"
          />
        </div>
        <div className="overnight-departures__text">
          The last bus has left. Good night.
        </div>
      </div>
    </div>
  );
};

export default OvernightDepartures;

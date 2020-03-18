import React from "react";

const TakeoverAlert = (): JSX.Element => {
  return (
    <div className="takeover-alert">
      <div className="takeover-alert__header">
        <div className="takeover-alert__icon-container">
          <img className="takeover-alert__icon-image" src="/images/alert.svg" />
        </div>
        <div className="takeover-alert__header-effect">Service Change</div>
      </div>

      <div className="takeover-alert__body">
        <div className="takeover-alert__description">
          We're running less service to help slow the spread of COVID-19.
        </div>
        <div className="takeover-alert__frequency">
          Expect weekend frequencies.
        </div>
        <div className="takeover-alert__link">
          More:
          <span className="takeover-alert__url"> mbta.com/coronavirus</span>
        </div>
      </div>
    </div>
  );
};

export default TakeoverAlert;

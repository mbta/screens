import React from "react";

const TakeoverInlineAlert = (): JSX.Element => {
  return (
    <div className="takeover-inline-alert">
      <div className="takeover-inline-alert__badge">
        <div className="takeover-inline-alert__image">
          <img
            className="takeover-inline-alert__icon"
            src="/images/alert.svg"
          />
        </div>
        <div className="takeover-inline-alert__text">
          We're running less service to help slow the spread of COVID-19.
        </div>
      </div>
    </div>
  );
};

export default TakeoverInlineAlert;

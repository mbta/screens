import React from "react";
import { imagePath } from "Util/util";

const TakeoverInlineAlert = (): JSX.Element => {
  return (
    <div className="takeover-inline-alert">
      <div className="takeover-inline-alert__badge">
        <div className="takeover-inline-alert__image">
          <img
            className="takeover-inline-alert__icon"
            src={imagePath("alert.svg")}
          />
        </div>
        <div className="takeover-inline-alert__text">
          <div>
            We're running less service to help slow the spread of COVID-19.
          </div>
          <div>
            More:{" "}
            <span className="takeover-inline-alert__link">
              mbta.com/coronavirus
            </span>
          </div>
        </div>
      </div>
    </div>
  );
};

export default TakeoverInlineAlert;

import React from "react";

import { TimeRepresentation } from "Util/time_representation";

interface BaseDepartureTimeProps {
  time: TimeRepresentation;
  hideAmPm?: boolean;
}

const BaseDepartureTime = ({
  time,
  hideAmPm,
}: BaseDepartureTimeProps): JSX.Element => {
  if (time.type.toUpperCase() === "TEXT") {
    return (
      <div className="base-departure-time">
        <span className="base-departure-time__text">{time.text}</span>
      </div>
    );
  } else if (time.type.toUpperCase() === "MINUTES") {
    return (
      <div className="base-departure-time">
        <span className="base-departure-time__minutes">{time.minutes}</span>
        <span className="base-departure-time__minutes-label">m</span>
      </div>
    );
  } else if (time.type.toUpperCase() === "TIMESTAMP") {
    return (
      <div className="base-departure-time">
        <span className="base-departure-time__timestamp">{time.timestamp}</span>
        {!hideAmPm && (
          <span className="base-departure-time__ampm">{time.ampm}</span>
        )}
      </div>
    );
  } else {
    return null;
  }
};

export default BaseDepartureTime;

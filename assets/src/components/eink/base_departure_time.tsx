import React from "react";

import {TimeRepresentation} from "Util/time_representation";

interface BaseDepartureTimeProps {
  time: TimeRepresentation;
}

const BaseDepartureTime = ({time}: BaseDepartureTimeProps): JSX.Element => {
  if (time.type === "TEXT") {
    return (
      <div className="base-departure-time">
        <span className="base-departure-time__text">{time.text}</span>
      </div>
    );
  } else if (time.type === "MINUTES") {
    return (
      <div className="base-departure-time">
        <span className="base-departure-time__minutes">{time.minutes}</span>
        <span className="base-departure-time__minutes-label">m</span>
      </div>
    );
  } else if (time.type === "TIMESTAMP") {
    return (
      <div className="base-departure-time">
        <span className="base-departure-time__timestamp">{time.timestamp}</span>
        <span className="base-departure-time__ampm">{time.ampm}</span>
      </div>
    );
  } else {
    return null;
  }
};

export default BaseDepartureTime;

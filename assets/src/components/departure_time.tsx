import moment from "moment";
import "moment-timezone";
import React from "react";

const classWithSize = (baseClass, size) => {
  return `${baseClass} ${baseClass}--${size}`;
};

const DepartureTime = ({ time, currentTimeString, modifier }): JSX.Element => {
  const departureTime = moment(time);
  const currentTime = moment(currentTimeString);
  const secondDifference = departureTime.diff(currentTime, "seconds");
  const minuteDifference = Math.round(secondDifference / 60);

  const size = modifier ? "small" : "large";

  let inner;
  if (secondDifference < 60) {
    inner = (
      <div>
        <span className={classWithSize("departure-time__now", size)}>Now</span>
      </div>
    );
  } else if (minuteDifference < 60) {
    inner = (
      <div>
        <span className={classWithSize("departure-time__minutes", size)}>
          {minuteDifference}
        </span>
        <span className={classWithSize("departure-time__minutes-label", size)}>
          m
        </span>
      </div>
    );
  } else {
    const timestamp = departureTime.tz("America/New_York").format("h:mm");
    const ampm = departureTime.tz("America/New_York").format("A");
    inner = (
      <div>
        <span className={classWithSize("departure-time__timestamp", size)}>
          {timestamp}
        </span>
        <span className={classWithSize("departure-time__ampm", size)}>
          {ampm}
        </span>
      </div>
    );
  }

  return <div className={classWithSize("departure-time", size)}>{inner}</div>;
};

export default DepartureTime;

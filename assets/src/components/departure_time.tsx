import moment from "moment";
import "moment-timezone";
import React from "react";

import { classWithSize } from "../util";

const DepartureTime = ({ time, currentTimeString, size }): JSX.Element => {
  const departureTime = moment(time);
  const currentTime = moment(currentTimeString);
  const secondDifference = departureTime.diff(currentTime, "seconds");
  const minuteDifference = Math.round(secondDifference / 60);

  if (secondDifference < 60) {
    return (
      <div className={classWithSize("departure-time", size)}>
        <span className={classWithSize("departure-time__now", size)}>Now</span>
      </div>
    );
  } else if (minuteDifference < 60) {
    return (
      <div className={classWithSize("departure-time", size)}>
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
    return (
      <div className={classWithSize("departure-time", size)}>
        <span className={classWithSize("departure-time__timestamp", size)}>
          {timestamp}
        </span>
        <span className={classWithSize("departure-time__ampm", size)}>
          {ampm}
        </span>
      </div>
    );
  }
};

export default DepartureTime;

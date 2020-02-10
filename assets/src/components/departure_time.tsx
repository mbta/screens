import moment from "moment";
import "moment-timezone";
import React from "react";

const DepartureTime = ({ time, currentTimeString, modifier }): JSX.Element => {
  const departureTime = moment(time);
  const currentTime = moment(currentTimeString);
  const secondDifference = departureTime.diff(currentTime, "seconds");
  const minuteDifference = Math.round(secondDifference / 60);

  let prefix;
  if (modifier) {
    prefix = "later-";
  } else {
    prefix = "";
  }

  if (secondDifference < 60) {
    return (
      <div className={prefix + "departure-time"}>
        <span className={prefix + "departure-time-now"}>Now</span>
      </div>
    );
  } else if (minuteDifference < 60) {
    return (
      <div className={prefix + "departure-time"}>
        <span className={prefix + "departure-time-minutes"}>
          {minuteDifference}
        </span>
        <span className={prefix + "departure-time-minutes-label"}>m</span>
      </div>
    );
  } else {
    const timestamp = departureTime.tz("America/New_York").format("h:mm");
    const ampm = departureTime.tz("America/New_York").format("A");
    return (
      <div className={prefix + "departure-time"}>
        <span className={prefix + "departure-time-timestamp"}>{timestamp}</span>
        <span className={prefix + "departure-time-ampm"}>{ampm}</span>
      </div>
    );
  }
};

export default DepartureTime;

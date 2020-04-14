import moment from "moment";
import "moment-timezone";
import React from "react";

const timeRepresentation = (departureTimeString, currentTimeString) => {
  const departureTime = moment(departureTimeString);
  const currentTime = moment(currentTimeString);
  const secondDifference = departureTime.diff(currentTime, "seconds");
  const minuteDifference = Math.round(secondDifference / 60);

  if (secondDifference < 60) {
    return { type: "TIME_NOW" };
  } else if (minuteDifference < 60) {
    return { type: "TIME_MINUTES", minutes: minuteDifference };
  } else {
    const timestamp = departureTime.tz("America/New_York").format("h:mm");
    const ampm = departureTime.tz("America/New_York").format("A");
    return {
      type: "TIME_TIMESTAMP",
      timestamp,
      ampm
    };
  }
};

const BaseDepartureTime = ({
  departureTimeString,
  currentTimeString
}): JSX.Element => {
  const time = timeRepresentation(departureTimeString, currentTimeString);

  if (time.type === "TIME_NOW") {
    return (
      <div className="base-departure-time">
        <span className="base-departure-time__now">Now</span>
      </div>
    );
  } else if (time.type === "TIME_MINUTES") {
    return (
      <div className="base-departure-time">
        <span className="base-departure-time__minutes">{time.minutes}</span>
        <span className="base-departure-time__minutes-label">m</span>
      </div>
    );
  } else if (time.type === "TIME_TIMESTAMP") {
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
export { timeRepresentation };

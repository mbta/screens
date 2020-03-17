import moment from "moment";
import "moment-timezone";
import React from "react";

const OvernightDepartures = ({ size, currentTimeString }): JSX.Element => {
  const currentTime = moment(currentTimeString)
    .tz("America/New_York")
    .format("h:mm");

  return (
    <div className="overnight-departures">
      <div className="overnight-departures__time">{currentTime}</div>
      <img src={`/images/overnight-static-${size}.png`} />
    </div>
  );
};

export default OvernightDepartures;

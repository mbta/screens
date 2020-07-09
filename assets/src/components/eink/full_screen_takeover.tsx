import moment from "moment";
import "moment-timezone";
import React from "react";

const FullScreenTakeover = ({ srcPath, currentTimeString }): JSX.Element => {
  const currentTime = moment(currentTimeString)
    .tz("America/New_York")
    .format("h:mm");

  return (
    <div className="full-screen-takeover__container">
      <div className="full-screen-takeover__time">{currentTime}</div>
      <img src={srcPath} />
    </div>
  );
};

export default FullScreenTakeover;

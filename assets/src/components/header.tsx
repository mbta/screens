import moment from "moment";
import "moment-timezone";
import React, { useLayoutEffect, useRef, useState } from "react";

const Header = ({ stopName, currentTimeString }): JSX.Element => {
  const ref = useRef(null);
  const [stopSize, setStopSize] = useState(1);
  const currentTime = moment(currentTimeString)
    .tz("America/New_York")
    .format("h:mm");

  useLayoutEffect(() => {
    const height = ref.current.clientHeight;
    if (height > 216) {
      setStopSize(stopSize - 1);
    }
  });

  const SIZES = ["small", "large"];
  const stopClassName = "header-stopname header-stopname-" + SIZES[stopSize];

  return (
    <div className="header">
      <div className="header-time">{currentTime}</div>
      <div className="header-realtime-indicator">
        <img
          className="header-realtime-indicator-icon"
          src="images/live-data-small.svg"
        ></img>
        UPDATED LIVE EVERY MINUTE
      </div>
      <div className={stopClassName} ref={ref}>
        {stopName}
      </div>
    </div>
  );
};

export default Header;

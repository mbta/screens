import moment from "moment";
import "moment-timezone";
import React, { useLayoutEffect, useRef, useState } from "react";

import { classWithSize } from "Util";

const iconForRoute = routeId => {
  if (routeId === "Green-B") {
    return "/images/GL-B.svg";
  }
  if (routeId === "Green-C") {
    return "/images/GL-C.svg";
  }
  if (routeId === "Green-D") {
    return "/images/GL-D.svg";
  }
  if (routeId === "Green-E") {
    return "/images/GL-E.svg";
  }
  return "/images/logo-white.svg";
};

const Header = ({ stopName, routeId, currentTimeString }): JSX.Element => {
  const SIZES = ["small", "large"];
  const MAX_HEIGHT = 216;

  const ref = useRef(null);
  const [stopSize, setStopSize] = useState(1);
  const currentTime = moment(currentTimeString)
    .tz("America/New_York")
    .format("h:mm");

  useLayoutEffect(() => {
    const height = ref.current.clientHeight;
    if (height > MAX_HEIGHT) {
      setStopSize(stopSize - 1);
    }
  });

  return (
    <div className="header">
      <div className="header__time">{currentTime}</div>
      <div className="header__realtime-indicator">
        <img
          className="header__realtime-indicator-icon"
          src="/images/live-data-small.svg"
        ></img>
        UPDATED LIVE EVERY MINUTE
      </div>
      <div className="header__stop-container">
        <div className="header__stop-container-route">
          <img
            className="header__stop-container-route-image"
            src={iconForRoute(routeId)}
          ></img>
        </div>
        <div
          className={classWithSize("header__stop-name", SIZES[stopSize])}
          ref={ref}
        >
          {stopName}
        </div>
      </div>
    </div>
  );
};

export default Header;

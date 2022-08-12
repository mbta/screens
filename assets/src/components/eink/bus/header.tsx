import React, { useLayoutEffect, useRef, useState } from "react";
import { getDatasetValue } from "Util/dataset";

import { classWithModifier, formatTimeString, imagePath } from "Util/util";

const Header = ({ stopName, currentTimeString }): JSX.Element => {
  const SIZES = ["small", "large"];
  const MAX_HEIGHT = 216;

  const ref = useRef(null);
  const [stopSize, setStopSize] = useState(1);
  const currentTime = formatTimeString(currentTimeString);

  useLayoutEffect(() => {
    const height = ref.current.clientHeight;
    if (height > MAX_HEIGHT) {
      setStopSize(stopSize - 1);
    }
  });

  const environmentName = getDatasetValue("environmentName");

  return (
    <div className="header">
      <div className="header__environment">
        {["screens-dev", "screens-dev-green"].includes(environmentName)
          ? environmentName
          : ""}
      </div>
      <div className="header__time">{currentTime}</div>
      <div className="header__realtime-indicator">
        <img
          className="header__realtime-indicator-icon"
          src={imagePath("live-data-small.svg")}
        ></img>
        UPDATED LIVE EVERY MINUTE
      </div>
      <div
        className={classWithModifier("header__stop-name", SIZES[stopSize])}
        ref={ref}
      >
        {stopName}
      </div>
    </div>
  );
};

export default Header;

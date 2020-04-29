import React from "react";

import { formatTimeString } from "Util";

const Header = ({stationName, currentTimeString}): JSX.Element => {
  const environmentName = document.getElementById("app").dataset
  .environmentName;

  const currentTime = formatTimeString(currentTimeString);

  return (
    <div className="header">
      <div className="header__environment">
        {["screens-dev", "screens-dev-green"].includes(environmentName)
          ? environmentName
          : ""}
      </div>
      <div className="header__time">
        {currentTime}
      </div>
      <div className="header__title">
        Upcoming Trips
      </div>
      <div className="header__station-name">
        {stationName}
      </div>
    </div>
  );
};

export default Header;

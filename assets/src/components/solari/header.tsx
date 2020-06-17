import React from "react";

import { formatTimeString } from "Util/util";

const Header = ({
  stationName,
  currentTimeString,
  sections,
  overhead,
}): JSX.Element => {
  const environmentName = document.getElementById("app").dataset
    .environmentName;

  const currentTime = formatTimeString(currentTimeString);
  const subtitle = overhead ? `${sections[0].name} Trips` : "Upcoming Trips";

  return (
    <div className="header">
      <div className="header__environment">
        {["screens-dev", "screens-dev-green"].includes(environmentName)
          ? environmentName
          : ""}
      </div>
      <div className="header__time">{currentTime}</div>
      <div className="header__content-container">
        <div className="header__station-name">{stationName}</div>
        <div className="header__subtitle">{subtitle}</div>
      </div>
    </div>
  );
};

export default Header;

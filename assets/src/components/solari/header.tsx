import React from "react";

import { formatTimeString, classWithModifier } from "Util/util";

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
  const sizeModifier = overhead ? "size-large" : "size-normal";

  return (
    <div className={classWithModifier("header", sizeModifier)}>
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

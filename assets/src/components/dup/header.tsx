import React from "react";

import { formatTimeString } from "Util/util";

const Header = ({ text, currentTimeString }): JSX.Element => {
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
      <div className="header__logo-container">
        <img className="header__logo-image" src="/images/logo-white.svg" />
      </div>
      <div className="header__content-container">
        <div className="header__text">{text}</div>
      </div>
      <div className="header__time">{currentTime}</div>
    </div>
  );
};

export default Header;

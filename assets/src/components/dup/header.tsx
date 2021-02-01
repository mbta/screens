import React from "react";

import { classWithModifier, formatTimeString, imagePath } from "Util/util";
import { DUP_VERSION } from "./version";

const patternMap: { [key: string]: string } = {
  hatched: "disruption",
  x: "closure",
  chevron: "suspension",
};

const CurrentTime = ({ currentTimeString }): JSX.Element => {
  const currentTime = formatTimeString(currentTimeString);

  return <div className="header__time">{currentTime}</div>;
};

const Pattern = ({ pattern }: { pattern: string }): JSX.Element => {
  const svgName = patternMap[pattern];

  const svgPath = imagePath(`dup-accent-${svgName}.svg`);

  return (
    <div className="header__accent-pattern-container">
      <img className="header__accent-pattern-image" src={svgPath} />
    </div>
  );
};

const Header = ({
  text,
  currentTimeString,
  pattern,
  color,
  code,
}): JSX.Element => {
  const environmentName = document.getElementById("app").dataset
    .environmentName;

  const className = color
    ? classWithModifier("header", `color-${color}`)
    : "header";

  const logoColor = color === "yellow" ? "black" : "white";

  return (
    <div className={className}>
      <div className="header__environment">
        {["screens-dev", "screens-dev-green"].includes(environmentName)
          ? environmentName
          : ""}
      </div>
      <div className="header__version">{DUP_VERSION}</div>
      {code && (
        <div className="header__error-code">Maintenance code: {code}</div>
      )}
      <div className="header__logo-container">
        <img
          className="header__logo-image"
          src={imagePath(`logo-${logoColor}.svg`)}
        />
      </div>
      <div className="header__content-container">
        <div className="header__text">{text}</div>
      </div>
      {currentTimeString && (
        <CurrentTime currentTimeString={currentTimeString} />
      )}
      {pattern && <Pattern pattern={pattern} />}
    </div>
  );
};

export default Header;

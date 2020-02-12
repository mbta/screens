import React from "react";

const parseSeverity = severity => {
  let delayDescription;
  let delayMinutes;

  // Note that delay severities are assumed to be between 3 and 9, inclusive
  // Probably want to fail gracefully if that's not true

  if (severity >= 8) {
    delayDescription = "more than";
    delayMinutes = 30 * (severity - 7);
  } else {
    delayDescription = "up to";
    delayMinutes = 5 * (severity - 1);
  }

  return {
    delayDescription,
    delayMinutes
  };
};

const DeparturesAlert = ({ inlineBadges }): JSX.Element => {
  let severity;

  if (inlineBadges && inlineBadges.length > 0) {
    severity = inlineBadges[0].severity;
  }

  if (severity === undefined) {
    return <div></div>;
  }

  const { delayDescription, delayMinutes } = parseSeverity(severity);

  return (
    <div className="departure-info">
      <span className={"departure-info__badge"}>
        <img className="departure-info__icon" src="images/alert.svg" />
        Delays {delayDescription + " "}
        <span className="departure-info__emphasis">{delayMinutes} minutes</span>
      </span>
    </div>
  );
};

export default DeparturesAlert;

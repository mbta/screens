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

const DeparturesAlert = ({ rowAlerts, alerts, modifier }): JSX.Element => {
  let severity;
  rowAlerts.forEach(alertId => {
    alerts.forEach(alert => {
      if (alertId === alert.id && alert.effect === "delay") {
        severity = alert.severity;
      }
    });
  });

  if (severity === undefined) {
    return <div></div>;
  }

  const { delayDescription, delayMinutes } = parseSeverity(severity);

  let prefix;
  if (modifier) {
    prefix = "later-";
  } else {
    prefix = "";
  }

  return (
    <div className={prefix + "departures-row-inline-badge-container"}>
      <span className={prefix + "departures-row-inline-badge"}>
        <img className="alert-badge-icon" src="images/alert.svg" />
        Delays {delayDescription + " "}
        <span className={prefix + "departures-row-inline-emphasis"}>
          {delayMinutes} minutes
        </span>
      </span>
    </div>
  );
};

export default DeparturesAlert;

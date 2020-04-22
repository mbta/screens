import React from "react";

const parseSeverity = (severity) => {
  let delayDescription;
  let delayMinutes;

  if (severity < 3) {
    severity = 3;
  }
  if (severity > 9) {
    severity = 9;
  }

  if (severity >= 8) {
    delayDescription = "more than";
    delayMinutes = 30 * (severity - 7);
  } else {
    delayDescription = "up to";
    delayMinutes = 5 * (severity - 1);
  }

  return {
    delayDescription,
    delayMinutes,
  };
};

const InlineAlert = ({ alertData }): JSX.Element => {
  if (alertData === undefined || alertData === null) {
    return null;
  }

  const severity = alertData.severity;

  if (severity === undefined) {
    return null;
  }

  const { delayDescription, delayMinutes } = parseSeverity(severity);

  return (
    <div className="inline-alert">
      <span className={"inline-alert__badge"}>
        <img className="inline-alert__icon" src="/images/alert.svg" />
        Delays {delayDescription + " "}
        <span className="inline-alert__emphasis">{delayMinutes} minutes</span>
      </span>
    </div>
  );
};

export default InlineAlert;

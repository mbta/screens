import React from "react";

const DepartureRoute = ({ route, modifier }): JSX.Element => {
  let prefix;
  if (modifier) {
    prefix = "later-";
  } else {
    prefix = "";
  }

  if (!route) {
    return <div className={prefix + "departure-route"}></div>;
  }

  let pillClass;
  let routeClass;
  if (route.includes("/")) {
    pillClass =
      prefix + "departure-route-pill " + prefix + "departure-route-pill-small";
    routeClass =
      prefix +
      "departure-route-number " +
      prefix +
      "departure-route-number-small";
  } else {
    pillClass =
      prefix + "departure-route-pill " + prefix + "departure-route-pill-medium";
    routeClass =
      prefix +
      "departure-route-number " +
      prefix +
      "departure-route-number-medium";
  }

  return (
    <div className={prefix + "departure-route"}>
      <div className={pillClass}>
        <span className={routeClass}>{route}</span>
      </div>
    </div>
  );
};

export default DepartureRoute;

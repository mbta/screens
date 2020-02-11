import React from "react";

import { classWithSize } from "../util";

const DepartureRoute = ({ route, size }): JSX.Element => {
  if (!route) {
    return <div className={classWithSize("departure-route", size)}></div>;
  }

  let pillSize;
  if (size === "small" && route.includes("/")) {
    pillSize = "xsmall";
  } else if (size === "small") {
    pillSize = "small";
  } else if (route.includes("/")) {
    pillSize = "medium";
  } else {
    pillSize = "large";
  }

  return (
    <div className={classWithSize("departure-route", size)}>
      <div className={classWithSize("departure-route__pill", pillSize)}>
        <span className={classWithSize("departure-route__number", pillSize)}>
          {route}
        </span>
      </div>
    </div>
  );
};

export default DepartureRoute;

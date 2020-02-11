import React from "react";

import { classWithSize } from "../util";

const DepartureDestination = ({ destination, modifier }): JSX.Element => {
  let prefix;
  if (modifier) {
    prefix = "later-";
  } else {
    prefix = "";
  }

  const size = modifier ? "small" : "large";

  let inner;
  if (destination === undefined) {
    inner = <div></div>;
  } else if (destination.includes("via")) {
    const parts = destination.split(" via ");
    const primaryDestination = parts[0];
    const secondaryDestination = "via " + parts[1];

    inner = (
      <div className={classWithSize("departure-destination__container", size)}>
        <div className={classWithSize("departure-destination__primary", size)}>
          {primaryDestination}
        </div>
        <div
          className={classWithSize("departure-destination__secondary", size)}
        >
          {secondaryDestination}
        </div>
      </div>
    );
  } else {
    inner = (
      <div className={classWithSize("departure-destination__container", size)}>
        <div className={classWithSize("departure-destination__primary", size)}>
          {destination}
        </div>
      </div>
    );
  }

  return (
    <div className={classWithSize("departure-destination", size)}>{inner}</div>
  );
};

export default DepartureDestination;

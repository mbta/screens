import React from "react";

import { classWithModifier } from "Util";

const DepartureDestination = ({ destination, size }): JSX.Element => {
  let inner;
  if (destination === undefined) {
    inner = <div></div>;
  } else if (destination.includes("via")) {
    const parts = destination.split(" via ");
    const primaryDestination = parts[0];
    const secondaryDestination = "via " + parts[1];

    inner = (
      <div
        className={classWithModifier("departure-destination__container", size)}
      >
        <div
          className={classWithModifier("departure-destination__primary", size)}
        >
          {primaryDestination}
        </div>
        <div
          className={classWithModifier(
            "departure-destination__secondary",
            size
          )}
        >
          {secondaryDestination}
        </div>
      </div>
    );
  } else {
    inner = (
      <div
        className={classWithModifier("departure-destination__container", size)}
      >
        <div
          className={classWithModifier("departure-destination__primary", size)}
        >
          {destination}
        </div>
      </div>
    );
  }

  return (
    <div className={classWithModifier("departure-destination", size)}>
      {inner}
    </div>
  );
};

export default DepartureDestination;

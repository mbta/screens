import React from "react";

const BaseDepartureDestination = ({ destination }): JSX.Element => {
  if (!destination) {
    return null;
  }

  if (destination.includes("via")) {
    const parts = destination.split(" via ");
    const primaryDestination = parts[0];
    const secondaryDestination = "via " + parts[1];

    return (
      <div className="base-departure-destination__container">
        <div className="base-departure-destination__primary">
          {primaryDestination}
        </div>
        <div className="base-departure-destination__secondary">
          {secondaryDestination}
        </div>
      </div>
    );
  } else {
    return (
      <div className="base-departure-destination__container">
        <div className="base-departure-destination__primary">{destination}</div>
      </div>
    );
  }
};

export default BaseDepartureDestination;

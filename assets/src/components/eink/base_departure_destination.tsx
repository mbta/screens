import React from "react";

const splitDestination = (destination) => {
  if (destination.includes("via")) {
    const parts = destination.split(" via ");
    const primaryDestination = parts[0];
    const secondaryDestination = "via " + parts[1];
    return [primaryDestination, secondaryDestination];
  } else if (destination.includes("(")) {
    const parts = destination.split(" (");
    const primaryDestination = parts[0].trim();
    const secondaryDestination = "(" + parts[1];
    return [primaryDestination, secondaryDestination];
  } else {
    return [destination];
  }
};

const BaseDepartureDestination = ({ destination }): JSX.Element => {
  if (!destination) {
    return null;
  }

  const [primaryDestination, secondaryDestination] = splitDestination(
    destination
  );

  if (secondaryDestination) {
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

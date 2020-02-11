import React from "react";

const DepartureDestination = ({ destination, modifier }): JSX.Element => {
  let prefix;
  if (modifier) {
    prefix = "later-";
  } else {
    prefix = "";
  }

  if (destination === undefined) {
    return <div className={prefix + "departure-destination"}></div>;
  }

  if (destination.includes("via")) {
    const parts = destination.split(" via ");
    const primaryDestination = parts[0];
    const secondaryDestination = "via " + parts[1];

    return (
      <div className={prefix + "departure-destination"}>
        <div className={prefix + "departure-destination-container"}>
          <div className={prefix + "departure-destination-primary"}>
            {primaryDestination}
          </div>
          <div className={prefix + "departure-destination-secondary"}>
            {secondaryDestination}
          </div>
        </div>
      </div>
    );
  } else {
    return (
      <div className={prefix + "departure-destination"}>
        <div className={prefix + "departure-destination-container"}>
          <div className={prefix + "departure-destination-primary"}>
            {destination}
          </div>
        </div>
      </div>
    );
  }
};

export default DepartureDestination;

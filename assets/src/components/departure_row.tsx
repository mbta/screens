import React from "react";

import DepartureDestination from "./departure_destination";
import DepartureRoute from "./departure_route";
import DepartureTime from "./departure_time";

const DepartureRow = ({
  currentTimeString,
  route,
  destination,
  time,
  first,
  modifier
}): JSX.Element => {
  let prefix;
  if (modifier) {
    prefix = "later-";
  } else {
    prefix = "";
  }

  return (
    <div className={prefix + "departure-row"}>
      <DepartureRoute route={route} modifier={modifier} />
      <DepartureDestination destination={destination} modifier={modifier} />
      <DepartureTime
        time={time}
        currentTimeString={currentTimeString}
        modifier={modifier}
      />
    </div>
  );
};

export default DepartureRow;

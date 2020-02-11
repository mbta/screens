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
  size
}): JSX.Element => {
  return (
    <div className={"departure-row"}>
      <DepartureRoute route={route} size={size} />
      <DepartureDestination destination={destination} size={size} />
      <DepartureTime
        time={time}
        currentTimeString={currentTimeString}
        size={size}
      />
    </div>
  );
};

export default DepartureRow;

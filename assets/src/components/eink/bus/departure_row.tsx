import React from "react";

import DepartureDestination from "Components/eink/bus/departure_destination";
import DepartureRoute from "Components/eink/bus/departure_route";
import DepartureTime from "Components/eink/bus/departure_time";

const DepartureRow = ({
  currentTimeString,
  route,
  destination,
  time,
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

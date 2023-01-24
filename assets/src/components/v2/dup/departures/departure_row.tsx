import React from "react";

import RoutePill from "Components/v2/departures/route_pill";
import Destination from "Components/v2/dup/departures/destination";
import DepartureTimes from "Components/v2/dup/departures/departure_times";

const DepartureRow = ({
  headsign,
  route,
  times_with_crowding: timesWithCrowding,
}) => {
  const routeText = Number(route.text);
  return (
    <div className="departure-row">
      <div className={"departure-row__route"}>
        <RoutePill
          {...route}
          size={isNaN(routeText) || routeText > 200 ? "small" : "large"}
        />
      </div>
      <div className="departure-row__destination">
        <Destination {...headsign} />
      </div>
      <div className="departure-row__time">
        <DepartureTimes timesWithCrowding={timesWithCrowding} />
      </div>
    </div>
  );
};

export default DepartureRow;

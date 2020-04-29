import React from "react";

import BaseRoutePill from "Components/eink/base_route_pill";
import BaseDepartureTime from "Components/eink/base_departure_time";
import BaseDepartureDestination from "Components/eink/base_departure_destination";

const Departure = ({
  route,
  destination,
  time,
  currentTimeString,
}): JSX.Element => {
  return (
    <div className="departure">
      <div className="departure-route">
        <BaseRoutePill route={route} />
      </div>
      <div className="departure-destination">
        <BaseDepartureDestination destination={destination} />
      </div>
      <div className="departure-time">
        <BaseDepartureTime
          departureTimeString={time}
          currentTimeString={currentTimeString}
        />
      </div>
    </div>
  );
};

export default Departure;

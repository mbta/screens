import React from "react";

import { standardTimeRepresentation } from "Util/time_representation";

import BaseDepartureTime from "Components/eink/base_departure_time";
import BaseDepartureDestination from "Components/eink/base_departure_destination";
import { DepartureRoutePill } from "Components/solari/route_pill";

const Departure = ({
  route,
  routeId,
  destination,
  time,
  currentTimeString,
  vehicleStatus,
  stopType,
  // TODO crowding, alerts?
}): JSX.Element => {
  const timeRepresentation = standardTimeRepresentation(
    time,
    currentTimeString,
    vehicleStatus,
    stopType
  );

  return (
    <div className="departure-container">
      <DepartureRoutePill route={route} routeId={routeId} />
      <div className="departure-destination">
        {destination && <BaseDepartureDestination destination={destination} />}
      </div>
      <div className="departure-time">
        <BaseDepartureTime time={timeRepresentation} />
      </div>
    </div>
  );
};

export default Departure;

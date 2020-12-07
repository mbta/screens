import React from "react";

import { standardTimeRepresentation } from "Util/time_representation";

import BaseDepartureTime from "Components/eink/base_departure_time";
import { DepartureRoutePill } from "Components/solari/route_pill";
import Destination from "Components/dup/destination";

const Departure = ({
  route,
  routeId,
  destination,
  time,
  currentTimeString,
  vehicleStatus,
  stopType,
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
        {destination && <Destination destination={destination} />}
      </div>
      <div className="departure-time">
        <BaseDepartureTime time={timeRepresentation} hideAmPm={true} />
      </div>
      <div className="departure-hairline" />
    </div>
  );
};

export default Departure;

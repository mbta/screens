import React from "react";

import { DepartureRoutePill } from "Components/solari/route_pill";
import Destination from "Components/dup/destination";
import Time from "Components/dup/time";

const Departure = ({
  route,
  routeId,
  destination,
  time,
  scheduledTime,
  currentTimeString,
  vehicleStatus,
  stopType,
  currentPage,
  trackNumber,
}): JSX.Element => {
  const noMinutes = routeId.startsWith("CR-") || routeId.startsWith("Boat-");

  return (
    <div className="departure-container">
      <DepartureRoutePill route={route} routeId={routeId} trackNumber={trackNumber} />
      <div className="departure-destination">
        {destination && (
          <Destination destination={destination} currentPage={currentPage} />
        )}
      </div>
      <Time
        time={time}
        scheduledTime={scheduledTime}
        currentTimeString={currentTimeString}
        vehicleStatus={vehicleStatus}
        stopType={stopType}
        noMinutes={noMinutes}
        currentPage={currentPage}
      />
      <div className="departure-hairline" />
    </div>
  );
};

export default Departure;

import React from "react";

import Departure from "Components/dup/departure";

const camelizeDepartureObject = ({
  id,
  route,
  destination,
  time,
  scheduled_time: scheduledTime,
  route_id: routeId,
  vehicle_status: vehicleStatus,
  alerts,
  stop_type: stopType,
  crowding_level: crowdingLevel,
}) => ({
  id,
  route,
  destination,
  time,
  scheduledTime,
  routeId,
  vehicleStatus,
  alerts,
  stopType,
  crowdingLevel,
});

const Section = ({ departures, currentTimeString }): JSX.Element => {
  return (
    <div className="section">
      {departures.map((departure) => (
        <Departure
          {...camelizeDepartureObject(departure)}
          currentTimeString={currentTimeString}
          key={departure.id}
        />
      ))}
      <div className="section-hairline" />
    </div>
  );
};

export default Section;

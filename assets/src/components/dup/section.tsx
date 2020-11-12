import React from "react";

import Departure from "Components/dup/departure";

const camelizeDepartureObject = ({
  id,
  route,
  destination,
  time,
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
    </div>
  );
};

export default Section;

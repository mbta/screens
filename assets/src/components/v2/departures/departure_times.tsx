import React from "react";

import DepartureTime from "Components/v2/departures/departure_time";
import DepartureCrowding from "Components/v2/departures/departure_crowding";

const DepartureTimes = ({ timesWithCrowding }) => {
  return (
    <div className="departure-times-with-crowding">
      {timesWithCrowding.map(({ id, time, crowding }) => (
        <div className="departure-time-with-crowding" key={id}>
          {crowding && <DepartureCrowding crowdingLevel={crowding} />}
          <DepartureTime {...time} />
        </div>
      ))}
    </div>
  );
};

export default DepartureTimes;

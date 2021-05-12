import React from "react";

import DepartureTime from "Components/v2/departures/departure_time";

const DepartureCrowding = (props) => {
  return null;
};

const DepartureTimes = ({ timesWithCrowding }) => {
  return (
    <div className="departure-times-with-crowding">
      {timesWithCrowding.map(({ time, crowding }, i) => (
        <div className="departure-time-with-crowding" key={i}>
          <DepartureCrowding {...crowding} />
          <DepartureTime {...time} />
        </div>
      ))}
    </div>
  );
};

export default DepartureTimes;

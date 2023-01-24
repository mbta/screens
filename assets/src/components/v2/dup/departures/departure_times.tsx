import React from "react";

import DepartureTime from "Components/v2/dup/departures/departure_time";

const DepartureTimes = ({ timesWithCrowding }) => {
  return (
    <div className="departure-times">
      {timesWithCrowding.map(({ id, time, scheduled_time }) => (
        <DepartureTime scheduled_time={scheduled_time} time={time} key={id} />
      ))}
    </div>
  );
};

export default DepartureTimes;

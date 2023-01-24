import React from "react";

import DepartureTime from "Components/v2/dup/departures/departure_time";

const DepartureTimes = ({ timesWithCrowding }) => {
  return (
    <>
      {timesWithCrowding.map(({ id, time, scheduled_time }) => (
        <DepartureTime scheduled_time={scheduled_time} time={time} key={id} />
      ))}
    </>
  );
};

export default DepartureTimes;

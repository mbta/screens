import React from "react";

import DepartureTime from "./departure_time";

const DepartureTimes = ({ timesWithCrowding, currentPage }) => {
  return (
    <>
      {timesWithCrowding.map(({ id, time, scheduled_time }) => (
        <DepartureTime
          scheduled_time={scheduled_time}
          time={time}
          key={id}
          currentPage={currentPage}
        />
      ))}
    </>
  );
};

export default DepartureTimes;

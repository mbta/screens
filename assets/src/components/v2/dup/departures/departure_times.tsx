import React, { ComponentType } from "react";

import { type TimeWithCrowding } from "Components/v2/departures/departure_times";
import DepartureTime from "./departure_time";

interface Props {
  timesWithCrowding: TimeWithCrowding[];
  currentPage: number;
}

const DepartureTimes: ComponentType<Props> = ({
  timesWithCrowding,
  currentPage,
}) => {
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

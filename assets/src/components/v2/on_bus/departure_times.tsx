import React, { ComponentType } from "react";

import { type TimeWithCrowding } from "Components/v2/departures/departure_times";
import DepartureTime from "./departure_time";

interface Props {
  timesWithCrowding: TimeWithCrowding[];
}

const DepartureTimes: ComponentType<Props> = ({ timesWithCrowding }) => {
  return (
    <>
      {timesWithCrowding.map(({ id, time }) => (
        <DepartureTime time={time} key={id} />
      ))}
    </>
  );
};

export default DepartureTimes;

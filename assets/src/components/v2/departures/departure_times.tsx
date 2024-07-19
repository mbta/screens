import React, { ComponentType } from "react";

import DepartureTime from "Components/v2/departures/departure_time";
import DepartureCrowding, {
  CrowdingLevel,
} from "Components/v2/departures/departure_crowding";

export type TimeWithCrowding = {
  id: string;
  time: DepartureTime;
  crowding: CrowdingLevel | null;
};

type Props = {
  timesWithCrowding: TimeWithCrowding[];
};

const DepartureTimes: ComponentType<Props> = ({ timesWithCrowding }) => {
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

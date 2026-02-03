import type { ComponentType } from "react";

import DepartureTime from "./departure_time";
import DepartureCrowding, { CrowdingLevel } from "./departure_crowding";

export type TimeWithCrowding = {
  id: string;
  time?: DepartureTime;
  scheduled_time?: DepartureTime;
  crowding: CrowdingLevel | null;
};

type Props = {
  timesWithCrowding: TimeWithCrowding[];
};

const DepartureTimes: ComponentType<Props> = ({ timesWithCrowding }) => {
  return (
    <div className="departure-times-with-crowding">
      {timesWithCrowding.map(({ id, time, scheduled_time, crowding }) => (
        <div className="departure-time-with-crowding" key={id}>
          {crowding && <DepartureCrowding crowdingLevel={crowding} />}
          <DepartureTime time={time} scheduled_time={scheduled_time} />
        </div>
      ))}
    </div>
  );
};

export default DepartureTimes;

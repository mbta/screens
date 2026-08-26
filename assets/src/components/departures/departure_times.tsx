import type { ComponentType } from "react";

import DepartureTime from "./departure_time";
import DepartureCrowding, { CrowdingLevel } from "./departure_crowding";

export type TimeWithCrowding = {
  id: string;
  time?: DepartureTime;
  time_in_epoch: number;
  scheduled_time?: DepartureTime;
  is_live: boolean;
  crowding: CrowdingLevel | null;
};

type Props = {
  timesWithCrowding: TimeWithCrowding[];
};

const DepartureTimes: ComponentType<Props> = ({ timesWithCrowding }) => {
  return (
    <div className="departure-times-with-crowding">
      {timesWithCrowding.map(
        ({ id, time, time_in_epoch, scheduled_time, is_live, crowding }) => (
          <div className="departure-time-with-crowding" key={id}>
            {crowding && <DepartureCrowding crowdingLevel={crowding} />}
            <DepartureTime
              time={time}
              time_in_epoch={time_in_epoch}
              scheduled_time={scheduled_time}
              is_live={is_live}
            />
          </div>
        ),
      )}
    </div>
  );
};

export default DepartureTimes;

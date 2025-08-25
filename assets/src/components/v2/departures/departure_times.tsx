import type { ComponentType } from "react";

import DepartureTime from "./departure_time";
import DepartureCrowding, { CrowdingLevel } from "./departure_crowding";

export type TimeWithCrowding = {
  id: string;
  time: DepartureTime;
  // Note: `scheduled_time` is currently only supported by the DUP version of
  // `DepartureTime`, but is always present in departures serialization.
  scheduled_time?: DepartureTime;
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

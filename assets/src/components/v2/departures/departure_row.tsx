import React, { ComponentType } from "react";

import RoutePill, { Pill } from "./route_pill";
import Destination from "./destination";
import DepartureTimes, { TimeWithCrowding } from "./departure_times";

type DepartureRow = {
  id: string;
  route: Pill;
  headsign: Destination;
  times_with_crowding: TimeWithCrowding[];
};

const DepartureRow: ComponentType<DepartureRow> = ({
  headsign,
  route,
  times_with_crowding: timesWithCrowding,
}) => {
  return (
    <div className="departure-row">
      <div // Keep pill aligned to top if there is a variation for the headsign.
        // Always aligning to top shifts destination text.
        className={
          "departure-row__route" + (headsign.variation ? "" : " center")
        }
      >
        <RoutePill pill={route} />
      </div>
      <div className="departure-row__destination">
        <Destination {...headsign} />
      </div>
      <div className="departure-row__time">
        
        <DepartureTimes timesWithCrowding={timesWithCrowding} //TODO: Don't need crowding /> 
      </div>
    </div>
  );
};

export default DepartureRow;

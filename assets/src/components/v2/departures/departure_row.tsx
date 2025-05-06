import React, { ComponentType } from "react";

import RoutePill, { Pill } from "./route_pill";
import Destination from "./destination";
import DepartureTimes, { TimeWithCrowding } from "./departure_times";

type DepartureRow = {
  id: string;
  route: Pill;
  headsign: Destination;
  times_with_crowding: TimeWithCrowding[];
  direction_id: 0 | 1;
  isBeforeDirectionSplit: boolean;
};

const DepartureRow: ComponentType<DepartureRow> = ({
  headsign,
  route,
  isBeforeDirectionSplit,
  times_with_crowding: timesWithCrowding,
}) => {
  return (
    <div
      className={
        "departure-row" + (isBeforeDirectionSplit ? " direction-split" : "")
      }
    >
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
        <DepartureTimes timesWithCrowding={timesWithCrowding} />
      </div>
    </div>
  );
};

export default DepartureRow;

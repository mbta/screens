import type { ComponentType } from "react";

import RoutePill, { Pill } from "./route_pill";
import Destination from "./destination";
import DepartureTimes, { TimeWithCrowding } from "./departure_times";
import { classWithModifiers } from "Util/utils";

type DepartureRow = {
  id: string;
  route: Pill;
  headsign: Destination;
  times_with_crowding: TimeWithCrowding[];
  direction_id: 0 | 1;
  is_first_trip: boolean;
  isBeforeDirectionSplit: boolean;
};

const DepartureRow: ComponentType<DepartureRow> = ({
  headsign,
  route,
  isBeforeDirectionSplit,
  times_with_crowding: timesWithCrowding,
}) => {
  return (
    <div className={departureRowClassName(route, isBeforeDirectionSplit)}>
      <div className="departure-row__route">
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

const departureRowClassName = (
  route: Pill,
  isBeforeDirectionSplit: boolean,
) => {
  const modifiers: string[] = [];
  if (route.type === "dual") {
    modifiers.push("wide-pill");
  }
  if (isBeforeDirectionSplit) {
    modifiers.push("direction-split");
  }
  return classWithModifiers("departure-row", modifiers);
};

export default DepartureRow;

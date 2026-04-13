import type { ComponentType } from "react";

import type DepartureRowBase from "Components/departures/departure_row";
import DepartureTimes from "Components/departures/departure_times";
import RoutePill, { Pill } from "Components/departures/route_pill";
import Destination from "./destination";
import { classWithModifiers } from "Util/utils";

const DepartureRow: ComponentType<DepartureRowBase> = ({
  headsign,
  route,
  times_with_crowding: timesWithCrowding,
  is_first_trip: isFirstTrip,
}) => {
  let classModifiers: String[] = [];
  if (wideRoutePill(route)) {
    classModifiers.push("extended-route_pill");
  }

  return (
    <div className={classWithModifiers("departure-row", classModifiers)}>
      <div className="departure-row__route">
        <RoutePill pill={route} />
      </div>
      <div className="departure-row__destination">
        <Destination {...headsign} />
      </div>
      <div className="departure-row__time">
        {isFirstTrip && <div className="departure-row__first">First</div>}
        <DepartureTimes timesWithCrowding={timesWithCrowding} />
      </div>
    </div>
  );
};

const wideRoutePill = (route_pill: Pill) => route_pill.type === "dual";

export default DepartureRow;

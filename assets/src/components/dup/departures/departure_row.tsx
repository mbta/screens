import type { ComponentType } from "react";

import type DepartureRowBase from "Components/departures/departure_row";
import DepartureTimes from "Components/departures/departure_times";
import RoutePill from "Components/departures/route_pill";
import Destination from "./destination";
import { classWithModifier } from "Util/utils";

const DepartureRow: ComponentType<DepartureRowBase> = ({
  headsign,
  route,
  times_with_crowding: timesWithCrowding,
  is_first_trip: isFirstTrip,
}) => {
  const parentClassModifier =
    route.type === "dual" ? "extended-route_pill" : "";

  return (
    <div className={classWithModifier("departure-row", parentClassModifier)}>
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

export default DepartureRow;

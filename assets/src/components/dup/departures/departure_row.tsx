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

  const classModifier = timesWithCrowding.some(
    (time) => time.time?.type === "timestamp" && time?.time.am_pm,
  )
    ? "shortened-headsign"
    : "";

  return (
    <div className={classWithModifier("departure-row", parentClassModifier)}>
      <div className={classWithModifier("departure-row__route", route.color)}>
        <RoutePill pill={route} />
      </div>
      <div className="departure-row__destination">
        <Destination {...headsign} classModifier={classModifier} />
      </div>
      <div className={classWithModifier("departure-row__time", classModifier)}>
        {isFirstTrip && <div className="departure-row__first">First</div>}
        <DepartureTimes timesWithCrowding={timesWithCrowding} />
      </div>
    </div>
  );
};

export default DepartureRow;

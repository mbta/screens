import type { ComponentType } from "react";

import type DepartureRowBase from "Components/departures/departure_row";
import DepartureTimes from "Components/departures/departure_times";
import RoutePill from "Components/departures/route_pill";
import Destination from "./destination";

const DepartureRow: ComponentType<DepartureRowBase> = ({
  headsign,
  route,
  times_with_crowding: timesWithCrowding,
}) => {
  return (
    <div className="departure-row">
      <div className="departure-row__route">
        <RoutePill pill={route} />
      </div>
      <div className={"departure-row__destination"}>
        <Destination {...headsign} />
      </div>
      <div className={"departure-row__time"}>
        <DepartureTimes timesWithCrowding={timesWithCrowding} />
      </div>
    </div>
  );
};

export default DepartureRow;

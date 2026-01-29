import type { ComponentType } from "react";

import type DepartureRowBase from "Components/departures/departure_row";
import DepartureTimes from "Components/departures/departure_times";
import RoutePill from "Components/departures/route_pill";
import Destination from "./destination";

interface Props extends DepartureRowBase {
  narrowHeadsign: boolean;
}

const DepartureRow: ComponentType<Props> = ({
  headsign,
  route,
  times_with_crowding: timesWithCrowding,
  narrowHeadsign,
}) => {
  return (
    <div className="departure-row">
      <div className="departure-row__route">
        <RoutePill pill={route} />
      </div>
      <div
        className={`departure-row__destination${narrowHeadsign ? "--narrow" : ""}`}
      >
        <Destination {...headsign} narrowHeadsign={narrowHeadsign} />
      </div>
      <div className={`departure-row__time${narrowHeadsign ? "--wide" : ""}`}>
        <DepartureTimes timesWithCrowding={timesWithCrowding} />
      </div>
    </div>
  );
};

export default DepartureRow;

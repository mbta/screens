import React, { ComponentType } from "react";

import type DepartureRowBase from "Components/v2/departures/departure_row";
import RoutePill, { Pill } from "Components/v2/departures/route_pill";
import Destination from "./destination";
import DepartureTimes, {
  TimeWithCrowding,
} from "../departures/departure_times";

interface Props extends DepartureRowBase {
  currentPage: number;
}

type DepartureRow = {
  id: string;
  route: Pill;
  headsign: Destination;
  times_with_crowding: TimeWithCrowding[];
};

const DepartureRow: ComponentType<Props> = ({
  headsign,
  route,
  times_with_crowding: timesWithCrowding,
}) => {
  return (
    <div className="departure-row">
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

export default DepartureRow;

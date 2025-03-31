import React, { ComponentType } from "react";

import type DepartureRowBase from "Components/v2/departures/departure_row";
import type DestinationBase from "Components/v2/departures/destination";
import RoutePill, { Pill } from "Components/v2/departures/route_pill";
import Destination from "./destination";
import { type TimeWithCrowding } from "Components/v2/departures/departure_times";
import DepartureTime from "Components/v2/departures/departure_time";

interface Props extends DepartureRowBase {
  currentPage: number;
}

type DepartureRow = {
  id: string;
  route: Pill;
  headsign: DestinationBase;
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
        <DepartureTime {...timesWithCrowding[0].time} />
      </div>
    </div>
  );
};

export default DepartureRow;

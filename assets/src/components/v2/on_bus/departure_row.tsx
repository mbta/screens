import React, { ComponentType } from "react";

import type DepartureRowBase from "Components/v2/departures/departure_row";
import RoutePill from "Components/v2/departures/route_pill";
import Destination from "../departures/destination";
import DepartureTimes from "../departures/departure_times";

interface Props extends DepartureRowBase {
  currentPage: number;
}

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
        <DepartureTimes
          timesWithCrowding={timesWithCrowding}
        />
      </div>
    </div>
  );
};

export default DepartureRow;

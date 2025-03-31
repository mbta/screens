import React, { ComponentType } from "react";

import type DepartureRowBase from "Components/v2/departures/departure_row";
import RoutePill from "Components/v2/departures/route_pill";
import Destination from "./destination";
import DepartureTimes from "./departure_times";

const LINE_HEIGHT = 138; // px

interface Props extends DepartureRowBase {
  currentPage: number;
}

const DepartureRow: ComponentType<Props> = ({
  headsign,
  route,
  times_with_crowding: timesWithCrowding,
  currentPage,
}) => {
  return (
    <div className="departure-row">
      <div className="departure-row__route">
        <RoutePill pill={route} />
      </div>
      <div className="departure-row__destination">
        <Destination
          {...headsign}
          currentPage={currentPage}
          lineHeight={LINE_HEIGHT}
        />
      </div>
      <div className="departure-row__time">
        <DepartureTimes
          timesWithCrowding={timesWithCrowding}
          currentPage={currentPage}
        />
      </div>
    </div>
  );
};

export default DepartureRow;

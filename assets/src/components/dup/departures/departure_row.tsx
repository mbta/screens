import type { ComponentType } from "react";

import type DepartureRowBase from "Components/departures/departure_row";
import DepartureTimes from "Components/departures/departure_times";
import RoutePill from "Components/departures/route_pill";
import Destination from "./destination";

const DepartureRow: ComponentType<DepartureRowBase> = ({
  headsign,
  route,
  times_with_crowding: timesWithCrowding,
  is_first_trip: isFirstTrip,
}) => {
  return (
    <div className="departure-row">
      <RoutePill pill={route} />
      <div className="departure-row__headsign-and-time-container">
        <Destination {...headsign} />
        <DepartureTimes
          timesWithCrowding={timesWithCrowding}
          isFirstTrip={isFirstTrip}
          enableTimePaging={true}
        />
      </div>
    </div>
  );
};

export default DepartureRow;

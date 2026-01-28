import type { ComponentType } from "react";

import type DepartureRowBase from "Components/departures/departure_row";
import RoutePill from "Components/departures/route_pill";
import Destination from "./destination";
import DepartureTimes from "./departure_times";

interface Props extends DepartureRowBase {
  currentPage: number;
  narrowHeadsign: boolean;
}

const DepartureRow: ComponentType<Props> = ({
  headsign,
  route,
  times_with_crowding: timesWithCrowding,
  currentPage,
  narrowHeadsign
}) => {
  return (
    <div className="departure-row">
      <div className="departure-row__route">
        <RoutePill pill={route} />
      </div>
      <div className={`departure-row__destination${narrowHeadsign ? "--narrow":"" }`}>
        <Destination {...headsign} currentPage={currentPage} narrowHeadsign={narrowHeadsign} />
      </div>
      <div className={`departure-row__time${narrowHeadsign ? "--wide":"" }`}>
        <DepartureTimes
          timesWithCrowding={timesWithCrowding}
          currentPage={currentPage}
        />
      </div>
    </div>
  );
};

export default DepartureRow;

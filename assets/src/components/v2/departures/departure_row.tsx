import React, { ComponentType } from "react";

import RoutePill, { Pill } from "Components/v2/departures/route_pill";
import Destination from "Components/v2/departures/destination";
import DepartureTimes, {
  TimeWithCrowding,
} from "Components/v2/departures/departure_times";
import DepartureAlerts from "Components/v2/departures/departure_alerts";

type DepartureRow = {
  id: string;
  route: Pill;
  headsign: Destination;
  times_with_crowding: TimeWithCrowding[];
  // currently the server always sets this to an empty array; will be removed
  inline_alerts: any[];
};

const DepartureRow: ComponentType<DepartureRow> = ({
  headsign,
  route,
  times_with_crowding: timesWithCrowding,
  inline_alerts: inlineAlerts,
}) => {
  return (
    <div className="departure-row">
      <div // Keep pill aligned to top if there is a variation for the headsign.
        // Always aligning to top shifts destination text.
        className={
          "departure-row__route" + (headsign.variation ? "" : " center")
        }
      >
        <RoutePill {...route} />
      </div>
      <div className="departure-row__destination">
        <Destination {...headsign} />
      </div>
      <div className="departure-row__time">
        <DepartureTimes timesWithCrowding={timesWithCrowding} />
      </div>
      {inlineAlerts.length > 0 && (
        <div className="departure-row__alerts">
          <DepartureAlerts alerts={inlineAlerts} />
        </div>
      )}
    </div>
  );
};

export default DepartureRow;

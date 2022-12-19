import React from "react";

import RoutePill from "Components/v2/departures/route_pill";
import Destination from "Components/v2/departures/destination";
import DepartureTimes from "Components/v2/departures/departure_times";
import DepartureAlerts from "Components/v2/departures/departure_alerts";

const DepartureRow = ({
  headsign,
  route,
  times_with_crowding: timesWithCrowding,
  inline_alerts: inlineAlerts,
}) => {
  return (
    <div className="departure-row">
      <div
        // Keep pill aligned to top if there is a variation for the headsign.
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

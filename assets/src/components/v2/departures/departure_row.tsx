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
      <div className="departure-row__route">
        <RoutePill {...route} />
      </div>
      <div className="departure-row__destination">
        <Destination {...headsign} />
      </div>
      <div className="departure-row__time">
        <DepartureTimes timesWithCrowding={timesWithCrowding} />
      </div>
      <div className="departure-row__alerts">
        <DepartureAlerts data={inlineAlerts} />
      </div>
    </div>
  );
};

export default DepartureRow;

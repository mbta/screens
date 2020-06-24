import React from "react";

import { standardTimeRepresentation } from "Util/time_representation";

import BaseDepartureTime from "Components/eink/base_departure_time";
import BaseDepartureDestination from "Components/eink/base_departure_destination";
import InlineAlertBadge from "Components/solari/inline_alert_badge";
import { DepartureRoutePill } from "Components/solari/route_pill";

import { classWithModifier } from "Util/util";

const Departure = ({
  route,
  routeId,
  destination,
  time,
  currentTimeString,
  vehicleStatus,
  stopType,
  alerts,
}): JSX.Element => {
  const viaModifier =
    destination && destination.includes(" via ") ? "with-via" : "no-via";

  const timeRepresentation = standardTimeRepresentation(
    time,
    currentTimeString,
    vehicleStatus,
    stopType
  );

  const timeAnimationModifier =
    timeRepresentation.type === "TEXT" ? "animated" : "static";

  return (
    <div className="departure-container">
      <div className={classWithModifier("departure", viaModifier)}>
        <DepartureRoutePill route={route} routeId={routeId} />
        <div className="departure-destination">
          {destination && (
            <BaseDepartureDestination destination={destination} />
          )}
        </div>
        <div
          className={classWithModifier("departure-time", timeAnimationModifier)}
        >
          <BaseDepartureTime time={timeRepresentation} />
        </div>
        {alerts.length > 0 && (
          <div className="departure__alerts-container">
            {alerts.map((alert) => (
              <InlineAlertBadge alert={alert} key={alert} />
            ))}
          </div>
        )}
      </div>
    </div>
  );
};

export default Departure;

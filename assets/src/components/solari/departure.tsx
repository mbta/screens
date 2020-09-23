import React from "react";

import { standardTimeRepresentation } from "Util/time_representation";

import BaseDepartureTime from "Components/eink/base_departure_time";
import BaseDepartureDestination from "Components/eink/base_departure_destination";
import InlineAlertBadge from "Components/solari/inline_alert_badge";
import {
  DepartureRoutePill,
  PlaceholderRoutePill,
} from "Components/solari/route_pill";

import { classWithModifier, classWithModifiers } from "Util/util";

const Departure = ({
  route,
  routeId,
  destination,
  time,
  currentTimeString,
  vehicleStatus,
  stopType,
  alerts,
  crowdingLevel,
  overhead,
  groupStart,
  groupEnd,
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

  const containerModifiers = [];
  if (groupStart) {
    containerModifiers.push("group-start");
  }
  if (groupEnd) {
    containerModifiers.push("group-end");
  }

  return (
    <div
      className={classWithModifiers("departure-container", containerModifiers)}
    >
      <div className={classWithModifier("departure", viaModifier)}>
        {groupStart ? (
          <DepartureRoutePill route={route} routeId={routeId} />
        ) : (
          <PlaceholderRoutePill />
        )}
        <div className="departure-destination">
          {destination && groupStart && (
            <BaseDepartureDestination destination={destination} />
          )}
        </div>
        {!overhead && (
          <div className="departure-crowding">
            {crowdingLevel && (
              <img
                className="departure-crowding__image"
                src={`/images/crowding-color-level-${crowdingLevel}.svg`}
              />
            )}
          </div>
        )}
        <div
          className={classWithModifier("departure-time", timeAnimationModifier)}
        >
          <BaseDepartureTime time={timeRepresentation} />
        </div>
        {groupStart && alerts.length > 0 && (
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

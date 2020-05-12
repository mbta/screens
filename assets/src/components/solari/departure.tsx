import React from "react";

import { standardTimeRepresentation } from "Util/time_representation";

import BaseRoutePill from "Components/eink/base_route_pill";
import BaseDepartureTime from "Components/eink/base_departure_time";
import BaseDepartureDestination from "Components/eink/base_departure_destination";

import { classWithModifier } from "Util/util";

const routeToPill = (route, routeId) => {
  if (routeId === "Blue") {
    return { routeName: "BL", routePillColor: "blue" };
  }

  if (routeId === "Red") {
    return { routeName: "RL", routePillColor: "red" };
  }

  if (routeId === "Mattapan") {
    return { routeName: "M", routePillColor: "red" };
  }

  if (routeId === "Orange") {
    return { routeName: "OL", routePillColor: "orange" };
  }

  if (routeId.startsWith("CR")) {
    return { routeName: "CR", routePillColor: "purple" };
  }

  if (route.startsWith("SL")) {
    return { routeName: route, routePillColor: "silver" };
  }

  return { routeName: route, routePillColor: "yellow" };
};

const Departure = ({
  route,
  routeId,
  destination,
  time,
  currentTimeString,
  vehicleStatus,
}): JSX.Element => {
  const { routeName, routePillColor } = routeToPill(route, routeId);

  return (
    <div className="departure">
      <div className={classWithModifier("departure-route", routePillColor)}>
        <BaseRoutePill route={routeName} />
      </div>
      <div className="departure-destination">
        <BaseDepartureDestination destination={destination} />
      </div>
      <div className="departure-time">
        <BaseDepartureTime
          time={standardTimeRepresentation(
            time,
            currentTimeString,
            vehicleStatus
          )}
        />
      </div>
    </div>
  );
};

export default Departure;

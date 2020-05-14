import React from "react";

import BaseDepartureTime from "Components/eink/base_departure_time";
import BaseDepartureDestination from "Components/eink/base_departure_destination";
import BaseRoutePill from "Components/eink/base_route_pill";

import { einkTimeRepresentation } from "Util/time_representation";

const NearbyDeparturesTime = ({ time, currentTimeString }): JSX.Element => {
  return (
    <div className="nearby-departures-time">
      <BaseDepartureTime
        time={einkTimeRepresentation(time, currentTimeString)}
      />
    </div>
  );
};

const NearbyDeparturesRoute = ({ route }): JSX.Element => {
  return (
    <div className="nearby-departures-route">
      <BaseRoutePill route={route} />
    </div>
  );
};

const NearbyDeparturesDestination = ({ destination }): JSX.Element => {
  return (
    <div className="nearby-departures-destination">
      <BaseDepartureDestination destination={destination} />
    </div>
  );
};

const NearbyDeparturesRow = ({
  name,
  route,
  time,
  destination,
  currentTimeString,
}): JSX.Element => {
  return (
    <div className="nearby-departures-row">
      <div className="nearby-departures-row__header">
        <div className="nearby-departures-row__stop-name">{name}</div>
      </div>
      <div className="nearby-departures-row__body">
        <NearbyDeparturesRoute route={route} />
        <NearbyDeparturesDestination destination={destination} />
        <NearbyDeparturesTime
          time={time}
          currentTimeStirng={currentTimeString}
        />
      </div>
      <div className="nearby-departures__hairline"></div>
    </div>
  );
};

const NearbyDepartures = ({ data, currentTimeString }): JSX.Element => {
  if (!data || data.length === 0 || data.includes(null)) {
    return null;
  }

  return (
    <div className="nearby-departures">
      <div className="nearby-departures__header">
        <div className="nearby-departures__icon-container">
          <img
            className="nearby-departures__icon-image"
            src="/images/nearby.svg"
          />
        </div>
        <div className="nearby-departures__header-text">Nearby departures</div>
      </div>
      <div className="nearby-departures__hairline"></div>
      {data.map((row, i) => (
        <div key={i}>
          <NearbyDeparturesRow
            name={row.stop_name}
            route={row.route}
            time={row.time}
            destination={row.destination}
            currentTimeString={currentTimeString}
          />
        </div>
      ))}
    </div>
  );
};

export default NearbyDepartures;

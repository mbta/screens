import React from "react";

import BaseDepartureTime from "Components/eink/base_departure_time";

const NearbyDeparturesTime = ({ time, currentTimeString }): JSX.Element => {
  return (
    <div className="nearby-departures-time">
      <BaseDepartureTime
        departureTimeString={time}
        currentTimeString={currentTimeString}
      />
    </div>
  );
};

const NearbyDeparturesRoute = ({ route }): JSX.Element => {
  return (
    <div className="nearby-departures-route">
      <div className="nearby-departures-route__pill">
        <div className="nearby-departures-route__text">{route}</div>
      </div>
    </div>
  );
};

const NearbyDeparturesDestination = ({ destination }): JSX.Element => {
  if (destination === undefined) {
    return null;
  } else if (destination.includes("via")) {
    const parts = destination.split(" via ");
    const primaryDestination = parts[0];
    const secondaryDestination = "via " + parts[1];

    return (
      <div className="nearby-departures-destination">
        <div className="nearby-departures-destination__primary">
          {primaryDestination}
        </div>
        <div className="nearby-departures-destination__secondary">
          {secondaryDestination}
        </div>
      </div>
    );
  } else {
    return (
      <div className="nearby-departures-destination">
        <div className="nearby-departures-destination__primary">
          {destination}
        </div>
      </div>
    );
  }
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

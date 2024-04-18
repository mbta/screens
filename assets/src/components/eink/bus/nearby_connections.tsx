import React from "react";

import { classWithModifier, imagePath } from "Util/util";

const NearbyConnectionsRoute = ({ route, small }): JSX.Element => {
  const size = small === true ? "small" : "large";
  const pillClass = classWithModifier("nearby-connections-route__pill", size);
  const textClass = classWithModifier("nearby-connections-route__text", size);

  let routeElt;
  if (route.includes("CR-")) {
    route = route.replace("CR-", "");
    routeElt = (
      <span>
        <img
          className="nearby-connections-route__icon"
          src={imagePath("commuter-rail.svg")}
        ></img>
        {route}
      </span>
    );
  } else {
    routeElt = <span>{route}</span>;
  }

  return (
    <div className={pillClass}>
      <div className={textClass}>{routeElt}</div>
    </div>
  );
};

const NearbyConnectionsRow = ({ name, distance, routes }): JSX.Element => {
  return (
    <div className="nearby-connections-row">
      <div className="nearby-connections-row__header">
        <div className="nearby-connections-row__stop-name">
          {name.replace("Massachusetts", "Mass")}
        </div>
        <div className="nearby-connections-row__distance-label">
          <img
            className="nearby-connections-row__distance-icon"
            src={imagePath("nearby.svg")}
          ></img>
          <span className="nearby-connections-row__distance">{distance} </span>
          <span className="nearby-connections-row__distance-units">min</span>
        </div>
      </div>
      <div className="nearby-connections-row__routes">
        {routes.map((route) => (
          <div className="nearby-connections-route" key={route}>
            <NearbyConnectionsRoute
              route={route}
              small={name === "South Station"}
            />
          </div>
        ))}
      </div>
      <div className="nearby-connections__hairline"></div>
    </div>
  );
};

const NearbyConnections = ({ nearbyConnections }): JSX.Element | null => {
  if (!nearbyConnections || nearbyConnections.length === 0) {
    return null;
  }

  return (
    <div className="nearby-connections">
      <div className="nearby-connections__header">
        <div className="nearby-connections__icon-container">
          <img
            className="nearby-connections__icon-image"
            src={imagePath("nearby.svg")}
          />
        </div>
        <div className="nearby-connections__header-text">
          Nearby connections
        </div>
      </div>
      <div className="nearby-connections__hairline"></div>
      {nearbyConnections.map((row) => (
        <div key={row.name}>
          <NearbyConnectionsRow
            name={row.name}
            distance={row.distance}
            routes={row.routes}
          />
        </div>
      ))}
    </div>
  );
};

export default NearbyConnections;

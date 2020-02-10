import React from "react";

const NearbyConnectionsRoute = ({ route, small }): JSX.Element => {
  let pillClass;
  let textClass;

  if (small) {
    pillClass =
      "nearby-connections-route-pill nearby-connections-route-pill-small";
    textClass =
      "nearby-connections-route-text nearby-connections-route-text-small";
  } else {
    pillClass =
      "nearby-connections-route-pill nearby-connections-route-pill-normal";
    textClass =
      "nearby-connections-route-text nearby-connections-route-text-normal";
  }

  let routeElt;
  if (route.includes("CR-")) {
    route = route.replace("CR-", "");
    routeElt = (
      <span>
        <img
          className="nearby-connections-route-icon"
          src="images/commuter-rail.svg"
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
  const FEET_PER_MINUTE = 250;
  const FEET_PER_MILE = 5280;
  let distanceInMinutes = Math.round(
    (distance * FEET_PER_MILE) / FEET_PER_MINUTE
  );

  // No zero-minute walking times
  if (distanceInMinutes === 0) {
    distanceInMinutes = 1;
  }

  return (
    <div className="nearby-connections-row">
      <div className="nearby-connections-row-header">
        <div className="nearby-connections-row-stop-name">
          {name.replace("Massachusetts", "Mass")}
        </div>
        <div className="nearby-connections-row-distance-label">
          <img
            className="nearby-connections-distance-icon"
            src="images/nearby.svg"
          ></img>
          <span className="nearby-connections-row-distance">
            {distanceInMinutes}{" "}
          </span>
          <span className="nearby-connections-row-distance-units">min</span>
        </div>
      </div>
      <div className="nearby-connections-routes">
        {routes.map(route => (
          <div className="nearby-connections-route" key={route}>
            <NearbyConnectionsRoute
              route={route}
              small={name === "South Station"}
            />
          </div>
        ))}
      </div>
      <div className="nearby-connections-hairline"></div>
    </div>
  );
};

const NearbyConnections = ({ nearbyConnections }): JSX.Element => {
  if (!nearbyConnections) {
    return <div></div>;
  }

  return (
    <div className="nearby-connections-container">
      <div className="nearby-connections-header">
        <div className="nearby-connections-icon-container">
          <img className="nearby-connections-icon" src="images/nearby.svg" />
        </div>
        <div className="nearby-connections-header-text">Nearby connections</div>
      </div>
      <div className="nearby-connections-hairline"></div>
      {nearbyConnections.map(row => (
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

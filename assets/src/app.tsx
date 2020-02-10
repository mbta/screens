declare function require(name: string): string;
// tslint:disable-next-line
require("../css/app.scss");

import "phoenix_html";
import QRCode from "qrcode.react";
import React, {
  forwardRef,
  setState,
  useEffect,
  useLayoutEffect,
  useRef,
  useState
} from "react";
import ReactDOM from "react-dom";
import {
  BrowserRouter as Router,
  Route,
  Switch,
  useParams
} from "react-router-dom";

import moment from "moment";
import "moment-timezone";

const HomePage = (): JSX.Element => {
  return (
    <div className="logo">
      <img src="images/logo.svg" />
    </div>
  );
};

const MultiScreenPage = (): JSX.Element => {
  return (
    <div className="multi-screen-container">
      {[...Array(19)].map((_, i) => (
        <ScreenContainer id={i + 1} key={i} />
      ))}
    </div>
  );
};

const ScreenPage = (): JSX.Element => {
  const { id } = useParams();
  return (
    <div className="screen-container">
      <ScreenContainer id={id} />
    </div>
  );
};

const ScreenContainer = ({ id }): JSX.Element => {
  const [currentTimeString, setCurrentTimeString] = useState();
  const [stopName, setStopName] = useState();
  const [inlineAlerts, setInlineAlerts] = useState();
  const [globalAlert, setGlobalAlert] = useState();
  const [departureRows, setDepartureRows] = useState();
  const [departuresAlerts, setDeparturesAlerts] = useState();
  const [stopId, setStopId] = useState();
  const [nearbyConnections, setNearbyConnections] = useState();

  const doUpdate = async () => {
    const result = await fetch(`/api/${id}`);
    const json = await result.json();
    setCurrentTimeString(json.current_time);
    setStopName(json.stop_name);
    setInlineAlerts(json.inline_alerts);
    setGlobalAlert(json.global_alert);
    setDepartureRows(json.departure_rows);
    setDeparturesAlerts(json.departures_alerts);
    setStopId(json.stop_id);
    setNearbyConnections(json.nearby_connections);
  };

  useEffect(() => {
    doUpdate();

    const interval = setInterval(() => {
      doUpdate();
    }, 30000);

    return () => clearInterval(interval);
  }, []);

  const [numRows, setNumRows] = useState(7);
  const ref = useRef(null);

  useLayoutEffect(() => {
    const height = ref.current.clientHeight;
    if (height > 1312) {
      setNumRows(numRows - 1);
    }
  });

  const [bottomNumRows, setBottomNumRows] = useState(5);
  const bottomRef = useRef(null);
  useLayoutEffect(() => {
    if (bottomRef.current) {
      const height = bottomRef.current.clientHeight;
      if (height > 585) {
        setBottomNumRows(bottomNumRows - 1);
      }
    }
  });

  return (
    <div className="dual-screen-container">
      <TopScreenContainer
        stopName={stopName}
        currentTimeString={currentTimeString}
        departureRows={departureRows}
        alerts={inlineAlerts}
        departuresAlerts={departuresAlerts}
        numRows={numRows}
        ref={ref}
      />
      <BottomScreenContainer
        departureRows={departureRows}
        inlineAlerts={inlineAlerts}
        globalAlert={globalAlert}
        departuresAlerts={departuresAlerts}
        stopId={stopId}
        numRows={numRows}
        currentTime={currentTimeString}
        bottomNumRows={bottomNumRows}
        nearbyConnections={nearbyConnections}
        ref={bottomRef}
      />
    </div>
  );
};

const BottomScreenContainer = forwardRef(
  (
    {
      departureRows,
      inlineAlerts,
      globalAlert,
      departuresAlerts,
      stopId,
      numRows,
      currentTime,
      bottomNumRows,
      nearbyConnections
    },
    ref
  ): JSX.Element => {
    return (
      <div className="single-screen-container">
        <FlexZoneContainer
          inlineAlerts={inlineAlerts}
          globalAlert={globalAlert}
          departureRows={departureRows}
          numRows={numRows}
          currentTime={currentTime}
          departuresAlerts={departuresAlerts}
          bottomNumRows={bottomNumRows}
          nearbyConnections={nearbyConnections}
          ref={ref}
        />
        <FareInfo />
        <DigitalBridge stopId={stopId} />
      </div>
    );
  }
);

const FlexZoneContainer = forwardRef(
  (
    {
      inlineAlerts,
      globalAlert,
      departureRows,
      numRows,
      currentTime,
      departuresAlerts,
      bottomNumRows,
      nearbyConnections
    },
    ref
  ): JSX.Element => {
    // Check whether there are any later departures to show
    let showLaterDepartures;
    if (departureRows) {
      showLaterDepartures = numRows < departureRows.length;
    } else {
      showLaterDepartures = false;
    }

    if (showLaterDepartures && globalAlert) {
      // Later Departures + Alert
      return (
        <div className="flex-zone-container">
          <div className="flex-top-container">
            <LaterDepartures
              departureRows={departureRows}
              startIndex={numRows}
              currentTime={currentTime}
              alerts={inlineAlerts}
              departuresAlerts={departuresAlerts}
              bottomNumRows={bottomNumRows}
              ref={ref}
            />
          </div>
          <div className="flex-bottom-container">
            <FlexZoneAlert alert={globalAlert} />
          </div>
        </div>
      );
    } else if (showLaterDepartures) {
      // Later Departures + Nearby Connections
      return (
        <div className="flex-zone-container">
          <div className="flex-top-container">
            <LaterDepartures
              departureRows={departureRows}
              startIndex={numRows}
              currentTime={currentTime}
              alerts={inlineAlerts}
              departuresAlerts={departuresAlerts}
              bottomNumRows={bottomNumRows}
              ref={ref}
            />
          </div>
          <div className="flex-bottom-container">
            <NearbyConnections nearbyConnections={nearbyConnections} />
          </div>
        </div>
      );
    } else if (globalAlert) {
      // Nearby Connections + Alert
      return (
        <div className="flex-zone-container">
          <div className="flex-top-container">
            <NearbyConnections nearbyConnections={nearbyConnections} />
          </div>
          <div className="flex-bottom-container">
            <FlexZoneAlert alert={globalAlert} />
          </div>
        </div>
      );
    } else {
      // Nearby Connections + Service Map
      return (
        <div className="flex-zone-container">
          <div className="flex-top-container">
            <NearbyConnections nearbyConnections={nearbyConnections} />
          </div>
          <div className="flex-bottom-container">
            <ServiceMap />
          </div>
        </div>
      );
    }
  }
);

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

const NearbyConnectionsRow = ({ name, distance, routes }): JSX.Element => {
  const FEET_PER_MINUTE = 300; // need a real value for this
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

const ServiceMap = (): JSX.Element => {
  return <div className="flex-placeholder"></div>;
};

const LaterDepartures = forwardRef(
  (
    {
      departureRows,
      startIndex,
      currentTime,
      alerts,
      departuresAlerts,
      bottomNumRows
    },
    ref
  ): JSX.Element => {
    if (!departureRows) {
      return <div></div>;
    }

    const laterDepartureRows = departureRows.slice(
      startIndex,
      startIndex + bottomNumRows
    );
    const rows = buildDeparturesRows(
      laterDepartureRows,
      alerts,
      departuresAlerts,
      bottomNumRows
    );

    return (
      <div className="later-departures-container" ref={ref}>
        {rows.map((row, i) => (
          <div key={row.route + row.time + i}>
            <LaterDeparturesRow
              currentTime={currentTime}
              route={row.route}
              destination={row.destination}
              departureTimes={row.time}
              rowAlerts={row.alerts}
              alerts={alerts}
            />
          </div>
        ))}
      </div>
    );
  }
);

const LaterDeparturesRow = ({
  currentTime,
  route,
  destination,
  departureTimes,
  rowAlerts,
  alerts
}): JSX.Element => {
  return (
    <div className="later-departures-row">
      <div className="later-departure-row-before"></div>
      <div className="later-departures-row-container">
        {departureTimes.map((t, i) => (
          <LaterDepartureRow
            route={i === 0 ? route : undefined}
            destination={i === 0 ? destination : undefined}
            time={t}
            currentTime={currentTime}
            first={i === 0}
            key={route + t + i}
          />
        ))}
        <LaterDeparturesAlert rowAlerts={rowAlerts} alerts={alerts} />
      </div>
      <div className="later-departure-row-after"></div>
      <div className="later-departure-row-hairline"></div>
    </div>
  );
};

const LaterDeparturesAlert = ({ rowAlerts, alerts }): JSX.Element => {
  let severity;
  rowAlerts.forEach(alertId => {
    alerts.forEach(alert => {
      if (alertId === alert.id && alert.effect === "delay") {
        severity = alert.severity;
      }
    });
  });

  if (severity === undefined) {
    return <div></div>;
  }

  const { delayDescription, delayMinutes } = parseSeverity(severity);

  return (
    <div className="later-departures-row-inline-badge-container">
      <span className="later-departures-row-inline-badge">
        <img className="alert-badge-icon" src="images/alert.svg" />
        Delays {delayDescription + " "}
        <span className="later-departures-row-inline-emphasis">
          {delayMinutes} minutes
        </span>
      </span>
    </div>
  );
};

const LaterDepartureRow = ({
  route,
  destination,
  time,
  currentTime,
  first
}): JSX.Element => {
  return (
    <div className="later-departure-row">
      <LaterDepartureRoute route={route} />
      <LaterDepartureDestination destination={destination} />
      <LaterDepartureTime time={time} currentTimeString={currentTime} />
    </div>
  );
};

const LaterDepartureRoute = ({ route }): JSX.Element => {
  if (!route) {
    return <div className="later-departure-route"></div>;
  }

  return (
    <div className="later-departure-route">
      <div className="later-departure-route-pill">
        <span className="later-departure-route-number">{route}</span>
      </div>
    </div>
  );
};

const LaterDepartureDestination = ({ destination }): JSX.Element => {
  if (destination === undefined) {
    return <div className="later-departure-destination"></div>;
  }

  if (destination.includes("via")) {
    const parts = destination.split(" via ");
    const primaryDestination = parts[0];
    const secondaryDestination = "via " + parts[1];

    return (
      <div className="later-departure-destination">
        <div className="later-departure-destination-container">
          <div className="later-departure-destination-primary">
            {primaryDestination}
          </div>
          <div className="later-departure-destination-secondary">
            {secondaryDestination}
          </div>
        </div>
      </div>
    );
  } else {
    return (
      <div className="later-departure-destination">
        <div className="later-departure-destination-container">
          <div className="later-departure-destination-primary">
            {destination}
          </div>
        </div>
      </div>
    );
  }
};

const LaterDepartureTime = ({ time, currentTimeString }): JSX.Element => {
  const departureTime = moment(time);
  const currentTime = moment(currentTime);
  const minuteDifference = departureTime.diff(currentTime, "minutes");

  if (minuteDifference < 2) {
    return (
      <div className="later-departure-time-container">
        <span className="later-departure-time-now">Now</span>
      </div>
    );
  } else if (minuteDifference < 60) {
    return (
      <div className="later-departure-time-container">
        <span className="later-departure-time-minutes">{minuteDifference}</span>
        <span className="later-departure-time-minutes-label">m</span>
      </div>
    );
  } else {
    const timestamp = departureTime.tz("America/New_York").format("h:mm");
    const ampm = departureTime.tz("America/New_York").format("A");

    return (
      <div className="later-departure-time-container">
        <span className="later-departure-time-timestamp">{timestamp}</span>
        <span className="later-departure-time-ampm">{ampm}</span>
      </div>
    );
  }
};

const iconForAlert = alert => {
  return (
    {
      SERVICE_CHANGE: "alert",
      DETOUR: "bus",
      STOP_MOVE: "no-service",
      STOP_CLOSURE: "logo-white"
    }[alert.effect] || "alert"
  );
};

const FlexZoneAlert = ({ alert }): JSX.Element => {
  const updatedTime = moment(alert.updated_at);
  return (
    <div className="alert-container">
      <div className="alert-header">
        <div className="alert-header-icon-container">
          <img
            className="alert-icon-image"
            src={`images/${iconForAlert(alert)}.svg`}
          />
        </div>
        <div className="alert-header-effect">
          {alert.effect.replace("_", " ").replace(/\w\S*/g, txt => {
            return txt.charAt(0).toUpperCase() + txt.substr(1).toLowerCase();
          })}
        </div>
        <div className="alert-header-timestamp">
          Updated <br />
          {updatedTime.tz("America/New_York").format("M/D/Y · h:mm A")}
        </div>
      </div>

      <div className="alert-body">
        <div className="alert-body-description">{alert.header}</div>
      </div>
    </div>
  );
};

const FareInfo = (): JSX.Element => {
  return (
    <div className="fare-container">
      <div className="fare-icon-container">
        <img className="fare-icon-image" src="images/bus.svg" />
      </div>
      <div className="fare-info-container">
        <div className="fare-info-header">Local bus one-way</div>
        <div className="fare-info-link">More at www.mbta.com/fares</div>
        <div className="fare-info-rows">
          <div className="fare-info-row">
            <span className="fare-info-row-cost">$1.70 </span>
            <span className="fare-info-row-description">CharlieCard </span>
            <span className="fare-info-row-details">
              (1 free transfer to Local Bus)
            </span>
          </div>
          <div className="fare-info-row">
            <span className="fare-info-row-cost">$2.00 </span>
            <span className="fare-info-row-description">
              Cash or CharlieTicket{" "}
            </span>
            <span className="fare-info-row-details">(Limited Transfers)</span>
          </div>
        </div>
      </div>
    </div>
  );
};

const DigitalBridge = ({ stopId }): JSX.Element => {
  return (
    <div className="digital-bridge-container">
      <div className="digital-bridge-logo-container">
        <img
          className="digital-bridge-logo-image"
          src="images/logo-white.svg"
        />
      </div>
      <div className="digital-bridge-link-container">
        <div className="digital-bridge-link-description">
          Real time predictions and stop info on the go
        </div>
        <div className="digital-bridge-link-url">
          www.mbta.com/stops/{stopId}
        </div>
      </div>
      <div className="digital-bridge-qr-container">
        <div className="digital-bridge-qr-image-container">
          <QRCode
            className="digital-bridge-qr-image"
            size={112}
            value={"www.mbta.com/stops/" + stopId}
          />
        </div>
      </div>
    </div>
  );
};

const TopScreenContainer = forwardRef(
  (
    {
      stopName,
      currentTimeString,
      departureRows,
      alerts,
      departuresAlerts,
      numRows
    },
    ref
  ): JSX.Element => {
    return (
      <div className="single-screen-container">
        <Header stopName={stopName} currentTimeString={currentTimeString} />
        <DeparturesContainer
          currentTimeString={currentTimeString}
          departureRows={departureRows}
          alerts={alerts}
          departuresAlerts={departuresAlerts}
          numRows={numRows}
          ref={ref}
        />
      </div>
    );
  }
);

const Header = ({ stopName, currentTimeString }): JSX.Element => {
  const ref = useRef(null);
  const [stopSize, setStopSize] = useState(1);
  const currentTime = moment(currentTimeString)
    .tz("America/New_York")
    .format("h:mm");

  useLayoutEffect(() => {
    const height = ref.current.clientHeight;
    if (height > 216) {
      setStopSize(stopSize - 1);
    }
  });

  const SIZES = ["small", "large"];
  const stopClassName = "header-stopname header-stopname-" + SIZES[stopSize];

  return (
    <div className="header">
      <div className="header-time">{currentTime}</div>
      <div className="header-realtime-indicator">UPDATED LIVE EVERY MINUTE</div>
      <div className={stopClassName} ref={ref}>
        {stopName}
      </div>
    </div>
  );
};

const buildDeparturesRows = (
  departuresRows,
  alerts,
  departuresAlerts,
  numRows
) => {
  if (!departuresRows || !alerts || !departuresAlerts) {
    return [];
  }

  departuresRows = departuresRows.slice(0, numRows);

  const rows = [];
  departuresRows.forEach(row => {
    const rowAlerts = [];
    departuresAlerts.forEach(da => {
      const alertId = da[0];
      const departureId = da[1];

      if (row.id === departureId) {
        rowAlerts.push(alertId);
      }
    });

    if (rows.length === 0) {
      const newRow = Object.assign({}, row);
      newRow.time = [newRow.time];
      newRow.alerts = rowAlerts;
      rows.push(newRow);
    } else {
      const lastRow = rows[rows.length - 1];
      if (
        row.route === lastRow.route &&
        row.destination === lastRow.destination
      ) {
        lastRow.time.push(row.time);
        // Take union of rowAlerts?
      } else {
        const newRow = Object.assign({}, row);
        newRow.time = [newRow.time];
        newRow.alerts = rowAlerts;
        rows.push(newRow);
      }
    }
  });

  return rows;
};

const DeparturesContainer = forwardRef(
  (
    { currentTimeString, departureRows, alerts, departuresAlerts, numRows },
    ref
  ) => {
    const rows = buildDeparturesRows(
      departureRows,
      alerts,
      departuresAlerts,
      numRows
    );

    return (
      <div className="departures-container" ref={ref}>
        {rows.map((row, i) => (
          <DeparturesRow
            currentTimeString={currentTimeString}
            route={row.route}
            destination={row.destination}
            departureTimes={row.time}
            rowAlerts={row.alerts}
            alerts={alerts}
            key={row.route + row.time + i}
          />
        ))}
      </div>
    );
  }
);

const DeparturesRow = ({
  currentTimeString,
  route,
  destination,
  departureTimes,
  rowAlerts,
  alerts
}): JSX.Element => {
  return (
    <div className="departures-row">
      <div className="departure-row-before"></div>
      <div className="departures-row-container">
        {departureTimes.map((t, i) => (
          <DepartureRow
            currentTimeString={currentTimeString}
            route={i === 0 ? route : undefined}
            destination={i === 0 ? destination : undefined}
            time={t}
            first={i === 0}
            key={route + t + i}
          />
        ))}
        <DeparturesAlert rowAlerts={rowAlerts} alerts={alerts} />
      </div>
      <div className="departure-row-after"></div>
      <div className="departure-row-hairline"></div>
    </div>
  );
};

const parseSeverity = severity => {
  let delayDescription;
  let delayMinutes;

  // Note that delay severities are assumed to be between 3 and 9, inclusive
  // Probably want to fail gracefully if that's not true

  if (severity >= 8) {
    delayDescription = "more than";
    delayMinutes = 30 * (severity - 7);
  } else {
    delayDescription = "up to";
    delayMinutes = 5 * (severity - 1);
  }

  return {
    delayDescription,
    delayMinutes
  };
};

const DeparturesAlert = ({ rowAlerts, alerts }): JSX.Element => {
  let severity;
  rowAlerts.forEach(alertId => {
    alerts.forEach(alert => {
      if (alertId === alert.id && alert.effect === "delay") {
        severity = alert.severity;
      }
    });
  });

  if (severity === undefined) {
    return <div></div>;
  }

  const { delayDescription, delayMinutes } = parseSeverity(severity);

  return (
    <div className="departures-row-inline-badge-container">
      <span className="departures-row-inline-badge">
        <img className="alert-badge-icon" src="images/alert.svg" />
        Delays {delayDescription + " "}
        <span className="departures-row-inline-emphasis">
          {delayMinutes} minutes
        </span>
      </span>
    </div>
  );
};

const DepartureRow = ({
  currentTimeString,
  route,
  destination,
  time,
  first
}): JSX.Element => {
  return (
    <div className="departure-row">
      <DepartureRoute route={route} />
      <DepartureDestination destination={destination} />
      <DepartureTime time={time} currentTimeString={currentTimeString} />
    </div>
  );
};

const DepartureRoute = ({ route }): JSX.Element => {
  if (!route) {
    return <div className="departure-route"></div>;
  }

  return (
    <div className="departure-route">
      <div className="departure-route-pill">
        <span className="departure-route-number">{route}</span>
      </div>
    </div>
  );
};

const DepartureDestination = ({ destination }): JSX.Element => {
  if (destination === undefined) {
    return <div className="departure-destination"></div>;
  }

  if (destination.includes("via")) {
    const parts = destination.split(" via ");
    const primaryDestination = parts[0];
    const secondaryDestination = "via " + parts[1];

    return (
      <div className="departure-destination">
        <div className="departure-destination-container">
          <div className="departure-destination-primary">
            {primaryDestination}
          </div>
          <div className="departure-destination-secondary">
            {secondaryDestination}
          </div>
        </div>
      </div>
    );
  } else {
    return (
      <div className="departure-destination">
        <div className="departure-destination-container">
          <div className="departure-destination-primary">{destination}</div>
        </div>
      </div>
    );
  }
};

const DepartureTime = ({ time, currentTimeString }): JSX.Element => {
  const departureTime = moment(time);
  const currentTime = moment(currentTimeString);
  const minuteDifference = departureTime.diff(currentTime, "minutes");

  if (minuteDifference < 2) {
    return (
      <div className="departure-time">
        <span className="departure-time-now">Now</span>
      </div>
    );
  } else if (minuteDifference < 60) {
    return (
      <div className="departure-time">
        <span className="departure-time-minutes">{minuteDifference}</span>
        <span className="departure-time-minutes-label">m</span>
      </div>
    );
  } else {
    const timestamp = departureTime.format("h:mm");
    const ampm = departureTime.format("A");
    return (
      <div className="departure-time">
        <span className="departure-time-timestamp">{timestamp}</span>
        <span className="departure-time-ampm">{ampm}</span>
      </div>
    );
  }
};

const App = (): JSX.Element => {
  return (
    <Router>
      <Switch>
        <Route exact path="/">
          <MultiScreenPage />
        </Route>
        <Route path="/:id">
          <ScreenPage />
        </Route>
      </Switch>
    </Router>
  );
};

ReactDOM.render(<App />, document.getElementById("app"));

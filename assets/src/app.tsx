declare function require(name: string): string;
// tslint:disable-next-line
require("../css/app.scss");

import "phoenix_html";
import React, {
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
  const [alerts, setAlerts] = useState();
  const [departureRows, setDepartureRows] = useState();
  const [departuresAlerts, setDeparturesAlerts] = useState();

  const doUpdate = async () => {
    const result = await fetch(`/api/${id}`);
    const json = await result.json();
    setCurrentTimeString(json.current_time);
    setStopName(json.stop_name);
    setAlerts(json.alerts);
    setDepartureRows(json.departure_rows);
    setDeparturesAlerts(json.departures_alerts);
  };

  useEffect(() => {
    doUpdate();

    const interval = setInterval(() => {
      doUpdate();
    }, 5000);

    return () => clearInterval(interval);
  }, []);

  return (
    <div className="dual-screen-container">
      <TopScreenContainer
        stopName={stopName}
        currentTimeString={currentTimeString}
        departureRows={departureRows}
        alerts={alerts}
        departuresAlerts={departuresAlerts}
      />
      <div className="screen-spacer"></div>
      <BottomScreenContainer
        departureRows={departureRows}
        alerts={alerts}
        departuresAlerts={departuresAlerts}
      />
    </div>
  );
};

const BottomScreenContainer = ({
  departureRows,
  alerts,
  departuresAlerts
}): JSX.Element => {
  return <div className="single-screen-container"></div>;
};

const TopScreenContainer = ({
  stopName,
  currentTimeString,
  departureRows,
  alerts,
  departuresAlerts
}): JSX.Element => {
  return (
    <div className="single-screen-container">
      <Header stopName={stopName} currentTimeString={currentTimeString} />
      <DeparturesContainer
        currentTimeString={currentTimeString}
        departureRows={departureRows}
        alerts={alerts}
        departuresAlerts={departuresAlerts}
      />
    </div>
  );
};

const Header = ({ stopName, currentTimeString }): JSX.Element => {
  const ref = useRef(null);
  const [stopSize, setStopSize] = useState(2);
  const currentTime = moment(currentTimeString).format("h:mm");

  useLayoutEffect(() => {
    const height = ref.current.clientHeight;
    if (height > 216) {
      setStopSize(stopSize - 1);
    }
  });

  const SIZES = ["small", "medium", "large"];
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

  departuresRows = departuresRows.slice(0, numRows + 1);

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

const DeparturesContainer = ({
  currentTimeString,
  departureRows,
  alerts,
  departuresAlerts
}): JSX.Element => {
  const [numRows, setNumRows] = useState(7);
  const ref = useRef(null);

  useLayoutEffect(() => {
    const height = ref.current.clientHeight;
    if (height > 1312) {
      setNumRows(numRows - 1);
    }
  });

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
          key={row.route + row.time}
        />
      ))}
    </div>
  );
};

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
            last={i === departureTimes.length - 1}
            key={route + t}
          />
        ))}
        <DeparturesAlert rowAlerts={rowAlerts} alerts={alerts} />
        <div className="departure-row-after"></div>
        <div className="departure-row-hairline"></div>
      </div>
    </div>
  );
};

const parseAlert = header => {
  return header.split("up to ")[1].split(" minutes")[0];
};

const DeparturesAlert = ({ rowAlerts, alerts }): JSX.Element => {
  let header;
  rowAlerts.forEach(alertId => {
    alerts.forEach(alert => {
      if (alertId === alert.id && alert.effect === "DELAY") {
        header = alert.header;
      }
    });
  });

  if (header === undefined) {
    return <div></div>;
  }

  const delayMinutes = parseAlert(header);

  return (
    <div className="departures-row-inline-badge-container">
      <span className="departures-row-inline-badge">
        Delays up to{" "}
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
  first,
  last
}): JSX.Element => {
  return (
    <div className="departure-row">
      <DepartureRoute route={route} first={first} last={last} />
      <DepartureDestination
        destination={destination}
        first={first}
        last={last}
      />
      <DepartureTime
        time={time}
        currentTimeString={currentTimeString}
        first={first}
        last={last}
      />
    </div>
  );
};

const DepartureRoute = ({ route, first, last }): JSX.Element => {
  let containerClass = "departure-route";
  if (first) {
    containerClass += " departure-route-first";
  }

  if (first) {
    return (
      <div className={containerClass}>
        <div className="departure-route-pill">
          <span className="departure-route-number">{route}</span>
        </div>
      </div>
    );
  } else {
    return <div className={containerClass}></div>;
  }
};

const DepartureDestination = ({ destination, first, last }): JSX.Element => {
  const containerClass = "departure-destination";
  if (destination === undefined) {
    return <div className={containerClass}></div>;
  }

  if (destination.includes("via")) {
    const parts = destination.split(" via ");
    const primaryDestination = parts[0];
    const secondaryDestination = "via " + parts[1];

    return (
      <div className={containerClass}>
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
      <div className={containerClass}>
        <div className="departure-destination-container">
          <div className="departure-destination-primary">{destination}</div>
        </div>
      </div>
    );
  }
};

const DepartureTime = ({
  time,
  currentTimeString,
  first,
  last
}): JSX.Element => {
  const departureTime = moment(time);
  const currentTime = moment(currentTimeString);
  const minuteDifference = departureTime.diff(currentTime, "minutes");

  let containerClass = "departure-time";
  if (first) {
    containerClass += " departure-time-first";
  }

  if (minuteDifference < 2) {
    return (
      <div className={containerClass}>
        <span className="departure-time-now">Now</span>
      </div>
    );
  } else if (minuteDifference < 60) {
    return (
      <div className={containerClass}>
        <span className="departure-time-minutes">{minuteDifference}</span>
        <span className="departure-time-minutes-label">m</span>
      </div>
    );
  } else {
    return (
      <div className={containerClass}>
        <span className="departure-time-timestamp">
          {departureTime.format("h:mm A")}
        </span>
      </div>
    );
  }
};

const App = (): JSX.Element => {
  return (
    <Router>
      <Switch>
        <Route exact path="/">
          {/* <HomePage /> */}
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

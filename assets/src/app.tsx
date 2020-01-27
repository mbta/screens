declare function require(name: string): string;
// tslint:disable-next-line
require("../css/app.scss");

import "phoenix_html";
import React, { useEffect, useState } from "react";
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
    }, 30000);

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
  return (
    <div className="single-screen-container">
      <div>{JSON.stringify(alerts)}</div>
      <div>{JSON.stringify(departuresAlerts)}</div>
      <div>{JSON.stringify(departureRows)}</div>
    </div>
  );
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
      />
    </div>
  );
};

const Header = ({ stopName, currentTimeString }): JSX.Element => {
  const currentTime = moment(currentTimeString).format("h:mm");

  return (
    <div className="header">
      <div className="header-time">{currentTime}</div>
      <div className="header-realtime-indicator">UPDATED LIVE EVERY MINUTE</div>
      <div className="header-stopname">{stopName}</div>
    </div>
  );
};

const buildDeparturesRows = departuresRows => {
  if (!departuresRows) {
    return [];
  }

  departuresRows = departuresRows.slice(0, 5);

  const rows = [];
  departuresRows.forEach(row => {
    if (rows.length === 0) {
      const newRow = Object.assign({}, row);
      newRow.time = [newRow.time];
      rows.push(newRow);
    } else {
      const lastRow = rows[rows.length - 1];
      if (
        row.route === lastRow.route &&
        row.destination === lastRow.destination
      ) {
        lastRow.time.push(row.time);
      } else {
        const newRow = Object.assign({}, row);
        newRow.time = [newRow.time];
        rows.push(newRow);
      }
    }
  });

  return rows;
};

const DeparturesContainer = ({
  currentTimeString,
  departureRows
}): JSX.Element => {
  const rows = buildDeparturesRows(departureRows);

  return (
    <div className="departures-container">
      {rows.map(row => (
        <DeparturesRow
          currentTimeString={currentTimeString}
          route={row.route}
          destination={row.destination}
          departureTimes={row.time}
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
  departureTimes
}): JSX.Element => {
  return (
    <div className="departures-row">
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
        <div className="departure-row-hairline"></div>
      </div>
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
  let containerClass;
  if (first && last) {
    containerClass =
      "departure-route departure-route-first departure-route-last";
  } else if (first) {
    containerClass = "departure-route departure-route-first";
  } else if (last) {
    containerClass = "departure-route departure-route-last";
  } else {
    containerClass = "departure-route";
  }

  if (first === true) {
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
  let containerClass;
  if (first && last) {
    containerClass =
      "departure-destination departure-destination-first departure-destination-last";
  } else if (first) {
    containerClass = "departure-destination departure-destination-first";
  } else if (last) {
    containerClass = "departure-destination departure-destination-last";
  } else {
    containerClass = "departure-destination";
  }

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

  let timeContainerClass = "departure-time";
  if (first) {
    timeContainerClass += " departure-time-first";
  } else if (last) {
    timeContainerClass += " departure-time-last";
  }

  if (minuteDifference < 2) {
    return (
      <div className={timeContainerClass}>
        <span className="departure-time-now">Now</span>
      </div>
    );
  } else if (minuteDifference < 60) {
    return (
      <div className={timeContainerClass}>
        <span className="departure-time-minutes">{minuteDifference}</span>
        <span className="departure-time-minutes-label">m</span>
      </div>
    );
  } else {
    return (
      <div className={timeContainerClass}>
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

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

interface HeaderProps {
  stopName?: string;
  currentTime?: string;
}

interface RowProps {
  data?: any;
}

interface TimeProps {
  data?: any;
  currentTimeString?: any;
}

const HomePage = (): JSX.Element => {
  return (
    <div className="logo">
      <img src="images/logo.svg" />
    </div>
  );
};

const ScreenPage = (): JSX.Element => {
  const { id } = useParams();
  const [currentTime, setCurrentTime] = useState();
  const [stopName, setStopName] = useState();
  const [departureRows, setDepartureRows] = useState();

  const doUpdate = async () => {
    const result = await fetch(`/api/${id}`);
    const json = await result.json();
    setCurrentTime(json.current_time);
    setStopName(json.stop_name);
    setDepartureRows(json.departure_rows);
  };

  useEffect(() => {
    doUpdate();

    const interval = setInterval(() => {
      doUpdate();
    }, 5000);

    return () => clearInterval(interval);
  }, []);

  return (
    <div>
      <Header stopName={stopName} currentTime={currentTime} />
      <DepartureContainer
        data={departureRows}
        currentTimeString={currentTime}
      />
    </div>
  );
};

const Header = ({ stopName, currentTime }: HeaderProps): JSX.Element => {
  const timeString = moment(currentTime).format("h:mm");

  return (
    <div className="header">
      <div className="header-time">{timeString}</div>
      <div className="header-realtime-indicator">UPDATED LIVE EVERY MINUTE</div>
      <div className="header-stopname">{stopName}</div>
    </div>
  );
};

const DepartureContainer = ({
  data,
  currentTimeString
}: TimeProps): JSX.Element => {
  const rows = data || [];
  return (
    <div className="departures-container">
      {rows.map((row: any) => (
        <DepartureRow
          data={row}
          currentTimeString={currentTimeString}
          key={row.route + row.time}
        />
      ))}
    </div>
  );
};

const DepartureRow = ({ data, currentTimeString }: TimeProps): JSX.Element => {
  return (
    <div className="departure-container">
      <DepartureRoute data={data.route} />
      <DepartureDestination data={data.destination} />
      <DepartureTime data={data.time} currentTimeString={currentTimeString} />
    </div>
  );
};

const DepartureRoute = ({ data }: RowProps): JSX.Element => {
  return (
    <div className="departure-route-pill">
      <span className="departure-route-number">{data}</span>
    </div>
  );
};

const DepartureDestination = ({ data }: RowProps): JSX.Element => {
  if (data.includes("via")) {
    const parts = data.split(" via ");
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
          <div className="departure-destination-primary">{data}</div>
        </div>
      </div>
    );
  }
};

const DepartureTime = ({ data, currentTimeString }: TimeProps): JSX.Element => {
  const departureTime = moment(data);
  const currentTime = moment(currentTimeString);
  const minuteDifference = departureTime.diff(currentTime, "minutes");

  if (minuteDifference < 2) {
    return <div className="departure-time">Now</div>;
  } else if (minuteDifference < 60) {
    return <div className="departure-time">{minuteDifference}m</div>;
  } else {
    return (
      <div className="departure-time">{departureTime.format("h:mm A")}</div>
    );
  }
};

const App = (): JSX.Element => {
  return (
    <Router>
      <Switch>
        <Route exact path="/">
          <HomePage />
        </Route>
        <Route path="/:id">
          <ScreenPage />
        </Route>
      </Switch>
    </Router>
  );
};

ReactDOM.render(<App />, document.getElementById("app"));

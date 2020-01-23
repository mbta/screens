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

interface Props {
  screenId?: string;
  stopName?: string;
}

interface BodyProps {
  data?: any;
}

const HomePage = (): JSX.Element => {
  return (
    <div>
      <Header />
      <Body />
    </div>
  );
};

const ScreenPage = (): JSX.Element => {
  const { id } = useParams();
  const [stopName, setStopName] = useState();
  const [departureRows, setDepartureRows] = useState();

  useEffect(() => {
    const myFunction = async () => {
      const result = await fetch(`/api/${id}`);
      const json = await result.json();
      setStopName(json.stop_name);
      setDepartureRows(json.departure_rows);
    };

    myFunction();
  }, []);

  return (
    <div>
      <Header screenId={id} stopName={stopName} />
      <Body data={departureRows} />
    </div>
  );
};

const Header = ({ screenId, stopName }: Props): JSX.Element => {
  const [time, setTime] = useState(new Date().toLocaleTimeString());

  useEffect(() => {
    setTime(new Date().toLocaleTimeString());

    const interval = setInterval(() => {
      setTime(new Date().toLocaleTimeString());
    }, 10000);

    return () => clearInterval(interval);
  }, []);

  return (
    <div className="header">
      <span className="screen-id">
        #{screenId}: {stopName}
      </span>
      <span className="timestamp">{time}</span>
    </div>
  );
};

const Body = ({ data }: BodyProps): JSX.Element => {
  return <div className="logo">{JSON.stringify(data)}</div>;
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

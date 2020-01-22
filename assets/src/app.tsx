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
  stopId?: string;
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
  const [stopId, setStopId] = useState();

  useEffect(() => {
    const myFunction = async () => {
      const result = await fetch(`/api/${id}`);
      const json = await result.json();
      setStopId(json.stop_id);
    };

    myFunction();
  }, []);

  return (
    <div>
      <Header screenId={id} stopId={stopId} />
      <Body />
    </div>
  );
};

const Header = ({ screenId, stopId }: Props): JSX.Element => {
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
        #{screenId}: {stopId}
      </span>
      <span className="timestamp">{time}</span>
    </div>
  );
};

const Body = (): JSX.Element => {
  return (
    <div className="logo">
      <img src="images/logo.svg" />
    </div>
  );
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

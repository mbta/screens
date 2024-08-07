import initSentry from "Util/sentry";
initSentry("dup");

require("../../css/dup.scss");

import React from "react";
import ReactDOM from "react-dom";
import { BrowserRouter as Router, Route, Switch } from "react-router-dom";

import ScreenContainer from "Components/dup/screen_container";

import {
  ScreenPage,
  RotationPage,
  MultiRotationPage,
  SimulationPage,
} from "Components/dup/dup_screen_page";
import { isDup } from "Util/outfront";

const App = (): JSX.Element => {
  if (isDup()) {
    return <ScreenPage screenContainer={ScreenContainer} />;
  } else {
    return (
      <Router>
        <Switch>
          <Route exact path="/screen/dup">
            <MultiRotationPage screenContainer={ScreenContainer} />
          </Route>
          <Route exact path="/screen/:id/simulation">
            <SimulationPage screenContainer={ScreenContainer} />
          </Route>
          <Route path="/screen/:id/:rotationIndex">
            <ScreenPage screenContainer={ScreenContainer} />
          </Route>
          <Route path="/screen/:id">
            <RotationPage screenContainer={ScreenContainer} />
          </Route>
        </Switch>
      </Router>
    );
  }
};

ReactDOM.render(<App />, document.getElementById("app"));

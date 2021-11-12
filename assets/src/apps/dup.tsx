declare function require(name: string): string;
// tslint:disable-next-line
require("../../css/dup.scss");

import React from "react";
import ReactDOM from "react-dom";
import { BrowserRouter as Router, Route, Switch } from "react-router-dom";

import ScreenContainer, { ScreenLayout } from "Components/dup/screen_container";

import {
  ScreenPage,
  RotationPage,
  MultiRotationPage,
} from "Components/dup/dup_screen_page";
import { isDup } from "Util/util";
import useSentry from "Hooks/use_sentry";

const App = (): JSX.Element => {
  useSentry();
  if (isDup()) {
    return <ScreenPage screenContainer={ScreenContainer} />;
  } else {
    return (
      <Router>
        <Switch>
          <Route exact path="/screen/dup">
            <MultiRotationPage screenContainer={ScreenContainer} />
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

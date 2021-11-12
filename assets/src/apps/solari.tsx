declare function require(name: string): string;
// tslint:disable-next-line
require("../../css/solari.scss");

import * as Sentry from "@sentry/react";
import React from "react";
import ReactDOM from "react-dom";
import { BrowserRouter as Router, Route, Switch } from "react-router-dom";

import ScreenContainer, {
  ScreenLayout,
} from "Components/solari/screen_container";

import {
  AuditScreenPage,
  MultiScreenPage,
  ScreenPage,
} from "Components/eink/screen_page";

const sentryDsn = document.getElementById("app")?.dataset.sentry;
if (sentryDsn) {
  Sentry.init({
    dsn: sentryDsn,
  });
}

const App = (): JSX.Element => {
  return (
    <Router>
      <Switch>
        <Route exact path="/screen/solari">
          <MultiScreenPage screenContainer={ScreenContainer} />
        </Route>
        <Route exact path="/audit/solari">
          <AuditScreenPage screenLayout={ScreenLayout} />
        </Route>
        <Route path="/screen/:id">
          <ScreenPage screenContainer={ScreenContainer} />
        </Route>
      </Switch>
    </Router>
  );
};

ReactDOM.render(<App />, document.getElementById("app"));

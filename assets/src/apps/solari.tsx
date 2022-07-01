import initSentry from "Util/sentry";
initSentry();

declare function require(name: string): string;
// tslint:disable-next-line
require("../../css/solari.scss");

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
import NaughtyButton from "Components/naughty_button";

const App = (): JSX.Element => {
  return (
    <>
      <NaughtyButton appID="solari" />
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
    </>
  );
};

ReactDOM.render(<App />, document.getElementById("app"));

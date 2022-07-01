import initSentry from "Util/sentry";
initSentry();

declare function require(name: string): string;
// tslint:disable-next-line
require("../../css/bus_eink.scss");

import React from "react";
import ReactDOM from "react-dom";
import { BrowserRouter as Router, Route, Switch } from "react-router-dom";

import ScreenContainer, {
  ScreenLayout,
} from "Components/eink/bus/screen_container";

import {
  AuditScreenPage,
  MultiScreenPage,
  ScreenPage,
} from "Components/eink/screen_page";
import NaughtyButton from "Components/naughty_button";

const App = (): JSX.Element => {
  return (
    <>
      <NaughtyButton appID="bus_eink" />
      <Router>
        <Switch>
          <Route exact path="/screen/bus_eink">
            <MultiScreenPage screenContainer={ScreenContainer} />
          </Route>
          <Route exact path="/audit/bus_eink">
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

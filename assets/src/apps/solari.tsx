import initSentry from "Util/sentry";
initSentry("solari");

declare function require(name: string): string;
// tslint:disable-next-line
require("../../css/solari.scss");

import React, { useEffect } from "react";
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

const App = (): JSX.Element => {
  useEffect(addSolariWatchdogListener, []);

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

const addSolariWatchdogListener = () => {
  window.addEventListener("message", function (ev) {
    // message is formatted this way {type:"watchdog", data: counter++ }
    if (ev.data.type === "watchdog") {
      (ev?.source as Window)?.postMessage(ev.data, "*");
    }
  });
};

ReactDOM.render(<App />, document.getElementById("app"));

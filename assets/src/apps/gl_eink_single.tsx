declare function require(name: string): string;
// tslint:disable-next-line
require("../../css/gl_eink_single.scss");

import React from "react";
import ReactDOM from "react-dom";
import { BrowserRouter as Router, Route, Switch } from "react-router-dom";

import ScreenContainer, {
  ScreenLayout,
} from "Components/eink/green_line/single/screen_container";

import {
  AuditScreenPage,
  MultiScreenPage,
  ScreenPage,
} from "Components/eink/screen_page";

const App = (): JSX.Element => {
  return (
    <Router>
      <Switch>
        <Route exact path="/screen/gl_eink_single">
          <MultiScreenPage screenContainer={ScreenContainer} />
        </Route>
        <Route exact path="/audit/gl_eink_single">
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

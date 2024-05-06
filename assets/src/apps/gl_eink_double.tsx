import initSentry from "Util/sentry";
initSentry("gl_eink_double");

require("../../css/gl_eink_double.scss");

import React from "react";
import ReactDOM from "react-dom";
import { BrowserRouter as Router, Route, Switch } from "react-router-dom";

import ScreenContainer, {
  ScreenLayout,
} from "Components/eink/green_line/double/screen_container";

import {
  AuditScreenPage,
  MultiScreenPage,
  ScreenPage,
} from "Components/eink/screen_page";

const App = (): JSX.Element => {
  return (
    <Router>
      <Switch>
        <Route exact path="/screen/gl_eink_double">
          <MultiScreenPage screenContainer={ScreenContainer} />
        </Route>
        <Route exact path="/audit/gl_eink_double">
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

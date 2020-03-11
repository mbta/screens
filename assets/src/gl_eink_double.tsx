declare function require(name: string): string;
// tslint:disable-next-line
require("../css/gl_eink_double.scss");

import React from "react";
import ReactDOM from "react-dom";
import { BrowserRouter as Router, Route, Switch } from "react-router-dom";

import {
  MultiScreenPage,
  ScreenPage
} from "Components/eink/green_line/double/screen_page";

const App = (): JSX.Element => {
  return (
    <Router>
      <Switch>
        <Route exact path="/screen/gl_eink_double">
          <MultiScreenPage />
        </Route>
        <Route path="/screen/:id">
          <ScreenPage />
        </Route>
      </Switch>
    </Router>
  );
};

ReactDOM.render(<App />, document.getElementById("app"));

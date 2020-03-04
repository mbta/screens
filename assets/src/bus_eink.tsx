declare function require(name: string): string;
// tslint:disable-next-line
require("../css/bus_eink.scss");

import React from "react";
import ReactDOM from "react-dom";
import { BrowserRouter as Router, Route, Switch } from "react-router-dom";

import { MultiScreenPage, ScreenPage } from "./components/screen_page";

const App = (): JSX.Element => {
  return (
    <Router>
      <Switch>
        <Route exact path="/screen/bus_eink">
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

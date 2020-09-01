declare function require(name: string): string;
// tslint:disable-next-line
require("../../css/admin.scss");

import React from "react";
import ReactDOM from "react-dom";
import { HashRouter as Router, Route, Switch } from "react-router-dom";

import AdminNavbar from "Components/admin/admin_navbar";
import AdminForm from "Components/admin/admin_form";
import {
  AllScreensTable,
  BusScreensTable,
  GLSingleScreensTable,
  GLDoubleScreensTable,
  SolariScreensTable,
} from "Components/admin/admin_tables";

const App = (): JSX.Element => {
  return (
    <Router>
      <AdminNavbar />
      <Switch>
        <Route exact path="/">
          <AllScreensTable />
        </Route>
        <Route exact path="/all-screens">
          <AllScreensTable />
        </Route>
        <Route exact path="/bus-screens">
          <BusScreensTable />
        </Route>
        <Route exact path="/gl_single-screens">
          <GLSingleScreensTable />
        </Route>
        <Route exact path="/gl_double-screens">
          <GLDoubleScreensTable />
        </Route>
        <Route exact path="/solari-screens">
          <SolariScreensTable />
        </Route>
        <Route exact path="/json-editor">
          <AdminForm />
        </Route>
      </Switch>
    </Router>
  );
};

ReactDOM.render(<App />, document.getElementById("app"));

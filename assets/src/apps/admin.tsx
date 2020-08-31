declare function require(name: string): string;
// tslint:disable-next-line
require("../../css/admin.scss");

import React from "react";
import ReactDOM from "react-dom";
import { HashRouter as Router, Route, Switch } from "react-router-dom";

import AdminNavbar from "Components/admin/admin_navbar";
import AdminForm from "Components/admin/admin_form";
import AdminTable from "Components/admin/admin_table";

const App = (): JSX.Element => {
  return (
    <Router>
      <AdminNavbar />
      <Switch>
        <Route exact path="/">
          <AdminForm />
        </Route>
        <Route exact path="/all-screens-table">
          <AdminTable />
        </Route>
      </Switch>
    </Router>
  );
};

ReactDOM.render(<App />, document.getElementById("app"));

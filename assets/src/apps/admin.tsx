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
  SolariLargeScreensTable,
  DupScreensTable,
  BusEinkV2ScreensTable,
  GLEinkV2ScreensTable,
  SolariV2ScreensTable,
  SolariLargeV2ScreensTable,
  BusShelterV2ScreensTable,
} from "Components/admin/admin_tables";
import ImageManager from "Components/admin/admin_image_manager";
import Devops from "Components/admin/devops";

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
        <Route exact path="/solari-large-screens">
          <SolariLargeScreensTable />
        </Route>
        <Route exact path="/dup-screens">
          <DupScreensTable />
        </Route>
        <Route exact path="/bus-eink-v2-screens">
          <BusEinkV2ScreensTable />
        </Route>
        <Route exact path="/gl-eink-v2-screens">
          <GLEinkV2ScreensTable />
        </Route>
        <Route exact path="/solari-v2-screens">
          <SolariV2ScreensTable />
        </Route>
        <Route exact path="/solari-large-v2-screens">
          <SolariLargeV2ScreensTable />
        </Route>
        <Route exact path="/bus-eink-v2-screens">
          <BusEinkV2ScreensTable />
        </Route>
        <Route exact path="/gl-eink-v2-screens">
          <GLEinkV2ScreensTable />
        </Route>
        <Route exact path="/solari-v2-screens">
          <SolariV2ScreensTable />
        </Route>
        <Route exact path="/solari-large-v2-screens">
          <SolariLargeV2ScreensTable />
        </Route>
        <Route exact path="/bus-shelter-v2-screens">
          <BusShelterV2ScreensTable />
        </Route>
        <Route exact path="/json-editor">
          <AdminForm />
        </Route>
        <Route exact path="/image-manager">
          <ImageManager />
        </Route>
        <Route exact path="/devops">
          <Devops />
        </Route>
      </Switch>
    </Router>
  );
};

ReactDOM.render(<App />, document.getElementById("app"));

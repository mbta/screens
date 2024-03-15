declare function require(name: string): string;
// tslint:disable-next-line
require("../../css/admin.scss");

import React from "react";
import ReactDOM from "react-dom";
import { HashRouter as Router, Route, Switch } from "react-router-dom";

import AdminNavbar from "Components/admin/admin_navbar";
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
  BuswayV2ScreensTable,
  SolariLargeV2ScreensTable,
  BusShelterV2ScreensTable,
  PreFareV2ScreensTable,
  DupV2ScreensTable,
  TriptychV2ScreensTable
} from "Components/admin/admin_tables";
import AdminTriptychPlayerForm from "Components/admin/admin_triptych_player_form";
import ImageManager from "Components/admin/admin_image_manager";
import Devops from "Components/admin/devops";
import AdminScreenConfigForm from "Components/admin/admin_screen_config_form";

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
        <Route exact path="/dup-v2-screens">
          <DupV2ScreensTable />
        </Route>
        <Route exact path="/bus-eink-v2-screens">
          <BusEinkV2ScreensTable />
        </Route>
        <Route exact path="/gl-eink-v2-screens">
          <GLEinkV2ScreensTable />
        </Route>
        <Route exact path="/busway-v2-screens">
          <BuswayV2ScreensTable />
        </Route>
        <Route exact path="/solari-large-v2-screens">
          <SolariLargeV2ScreensTable />
        </Route>
        <Route exact path="/bus-shelter-v2-screens">
          <BusShelterV2ScreensTable />
        </Route>
        <Route exact path="/pre-fare-v2-screens">
          <PreFareV2ScreensTable />
        </Route>
        <Route exact path="/triptych-v2-screens">
          <TriptychV2ScreensTable />
        </Route>
        <Route exact path="/screens-json-editor">
          <AdminScreenConfigForm />
        </Route>
        <Route exact path="/triptych-player-json-editor">
          <AdminTriptychPlayerForm />
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

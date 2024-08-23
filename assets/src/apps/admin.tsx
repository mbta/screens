require("../../css/admin.scss");

import React, { ComponentType } from "react";
import ReactDOM from "react-dom";
import {
  BrowserRouter as Router,
  NavLink,
  Route,
  Switch,
} from "react-router-dom";
import weakKey from "weak-key";

import {
  AllScreensTable,
  SolariScreensTable,
  BusEinkV2ScreensTable,
  GLEinkV2ScreensTable,
  BuswayV2ScreensTable,
  BusShelterV2ScreensTable,
  PreFareV2ScreensTable,
  DupV2ScreensTable,
  TriptychV2ScreensTable,
} from "Components/admin/admin_tables";
import AdminScreenConfigForm from "Components/admin/admin_screen_config_form";
import AdminTriptychPlayerForm from "Components/admin/admin_triptych_player_form";
import ImageManager from "Components/admin/admin_image_manager";
import Devops from "Components/admin/devops";
import Inspector from "Components/admin/inspector";

const routes: [string, string, ComponentType][][] = [
  [["inspector", "🔍", Inspector]],
  [["", "All Screens", AllScreensTable]],
  [
    ["bus-eink-v2-screens", "Bus E-ink", BusEinkV2ScreensTable],
    ["bus-shelter-v2-screens", "Bus Shelter", BusShelterV2ScreensTable],
    ["dup-v2-screens", "DUP", DupV2ScreensTable],
    ["gl-eink-v2-screens", "GL E-ink", GLEinkV2ScreensTable],
    ["pre-fare-v2-screens", "Pre-Fare", PreFareV2ScreensTable],
    ["busway-v2-screens", "Sectional", BuswayV2ScreensTable],
    ["triptych-v2-screens", "Triptych", TriptychV2ScreensTable],
  ],
  [["solari-screens", "Solari (v1)", SolariScreensTable]],
  [
    ["screens-json-editor", "Config Editor", AdminScreenConfigForm],
    ["triptych-player-json-editor", "Triptych Editor", AdminTriptychPlayerForm],
  ],
  [["image-manager", "Image Manager", ImageManager]],
  [["devops", "Devops", Devops]],
];

const App = (): JSX.Element => {
  return (
    <Router basename="/admin">
      <div className="admin-navbar">
        {routes.map((group) => (
          <div key={weakKey(group)} className="admin-navbar__group">
            {group.map(([path, label]) => (
              <NavLink exact to={"/" + path} key={path}>
                {label}
              </NavLink>
            ))}
          </div>
        ))}
      </div>

      <Switch>
        {routes.map((group) =>
          group.map(([path, , Component]) => (
            <Route exact path={"/" + path} key={path}>
              <Component />
            </Route>
          )),
        )}
      </Switch>
    </Router>
  );
};

ReactDOM.render(<App />, document.getElementById("app"));

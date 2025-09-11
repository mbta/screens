import "../../css/admin.scss";

import { type ComponentType, StrictMode } from "react";
import { createRoot } from "react-dom/client";
import {
  BrowserRouter as Router,
  NavLink,
  Route,
  Routes,
} from "react-router-dom";
import weakKey from "weak-key";

import {
  AllScreensTable,
  BusEinkV2ScreensTable,
  GLEinkV2ScreensTable,
  BuswayV2ScreensTable,
  BusShelterV2ScreensTable,
  PreFareV2ScreensTable,
  DupV2ScreensTable,
  ElevatorV2ScreensTable,
} from "Components/admin/admin_tables";
import AdminScreenConfigForm from "Components/admin/admin_screen_config_form";
import ImageManager from "Components/admin/admin_image_manager";
import Devops from "Components/admin/devops";
import Inspector from "Components/admin/inspector";
import Tools from "Components/admin/tools";

const routes: [string, string, ComponentType][][] = [
  [["inspector", "🔍", Inspector]],
  [["", "All Screens", AllScreensTable]],
  [
    ["bus-eink-v2-screens", "Bus E-ink", BusEinkV2ScreensTable],
    ["bus-shelter-v2-screens", "Bus Shelter", BusShelterV2ScreensTable],
    ["dup-v2-screens", "DUP", DupV2ScreensTable],
    ["elevator-v2-screens", "Elevator", ElevatorV2ScreensTable],
    ["gl-eink-v2-screens", "GL E-ink", GLEinkV2ScreensTable],
    ["pre-fare-v2-screens", "Pre-Fare", PreFareV2ScreensTable],
    ["busway-v2-screens", "Sectional", BuswayV2ScreensTable],
  ],
  [
    ["screens-json-editor", "Config Editor", AdminScreenConfigForm],
    ["devops", "Devops", Devops],
    ["image-manager", "Image Manager", ImageManager],
    ["tools", "Tools", Tools],
  ],
];

const App = (): JSX.Element => {
  return (
    <Router basename="admin">
      <div className="admin-navbar">
        {routes.map((group) => (
          <div key={weakKey(group)} className="admin-navbar__group">
            {group.map(([path, label]) => (
              <NavLink to={path} key={path}>
                {label}
              </NavLink>
            ))}
          </div>
        ))}
      </div>

      <Routes>
        {routes.map((group) =>
          group.map(([path, , Component]) => (
            <Route path={path} key={path} element={<Component />} />
          )),
        )}
      </Routes>
    </Router>
  );
};

const root = createRoot(document.getElementById("app")!);
root.render(
  <StrictMode>
    <App />
  </StrictMode>,
);

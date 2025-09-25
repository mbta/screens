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
  BusEinkScreensTable,
  GLEinkScreensTable,
  BuswayScreensTable,
  BusShelterScreensTable,
  PreFareScreensTable,
  DupScreensTable,
  ElevatorScreensTable,
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
    ["bus-eink-screens", "Bus E-ink", BusEinkScreensTable],
    ["bus-shelter-screens", "Bus Shelter", BusShelterScreensTable],
    ["dup-screens", "DUP", DupScreensTable],
    ["elevator-screens", "Elevator", ElevatorScreensTable],
    ["gl-eink-screens", "GL E-ink", GLEinkScreensTable],
    ["pre-fare-screens", "Pre-Fare", PreFareScreensTable],
    ["busway-screens", "Sectional", BuswayScreensTable],
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

import "../../css/admin.scss";

import { type ComponentType, StrictMode } from "react";
import { createRoot } from "react-dom/client";
import { BrowserRouter as Router, NavLink, Route, Routes } from "react-router";

import ScreensTable from "Components/admin/table";
import AdminScreenConfigForm from "Components/admin/admin_screen_config_form";
import ImageManager from "Components/admin/admin_image_manager";
import Devops from "Components/admin/devops";
import Inspector from "Components/admin/inspector";
import Tools from "Components/admin/tools";

const routes: [string, string, ComponentType][] = [
  ["inspector", "🔍", Inspector],
  ["", "Screens Table", ScreensTable],
  ["screens-json-editor", "JSON Editor", AdminScreenConfigForm],
  ["devops", "Devops", Devops],
  ["image-manager", "Image Manager", ImageManager],
  ["tools", "Tools", Tools],
];

const App = (): JSX.Element => {
  return (
    <Router basename="admin">
      <nav className="admin-navbar">
        {routes.map(([path, label]) => (
          <NavLink to={path} key={path}>
            {label}
          </NavLink>
        ))}
      </nav>

      <Routes>
        {routes.map(([path, , Component]) => (
          <Route path={path} key={path} element={<Component />} />
        ))}
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

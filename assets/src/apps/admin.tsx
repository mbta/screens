import "../../css/admin.scss";

import { type ComponentType, StrictMode } from "react";
import { createRoot } from "react-dom/client";
import {
  createBrowserRouter,
  NavLink,
  RouterProvider,
  Outlet,
} from "react-router";

import AdminScreenConfigForm from "Components/admin/admin_screen_config_form";
import Editor from "Components/admin/editor";
import ImageManager from "Components/admin/admin_image_manager";
import Inspector from "Components/admin/inspector";
import Tools from "Components/admin/tools";

const routes: [string | undefined, string, ComponentType][] = [
  ["inspector", "🔍 Inspector", Inspector],
  [undefined, "📋 Screens Table", Editor],
  ["screens-json-editor", "📝 JSON Editor", AdminScreenConfigForm],
  ["image-manager", "🏞️ Image Manager", ImageManager],
  ["tools", "🛠️ Tools", Tools],
];

const NavLayout: ComponentType = () => (
  <>
    <nav className="admin-navbar">
      {routes.map(([path, label]) => (
        <NavLink key={path ?? ""} to={path ?? "/admin"} end={!path}>
          {label}
        </NavLink>
      ))}
    </nav>
    <Outlet />
  </>
);

const router = createBrowserRouter([
  {
    path: "/admin",
    Component: NavLayout,
    children: routes.map(([path, , Component]) => ({
      path,
      Component,
      index: !path,
    })),
  },
]);

const root = createRoot(document.getElementById("app")!);
root.render(
  <StrictMode>
    <RouterProvider router={router} />
  </StrictMode>,
);

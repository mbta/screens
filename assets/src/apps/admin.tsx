import "../../css/admin.scss";

import { type ComponentType, StrictMode } from "react";
import { createRoot } from "react-dom/client";
import {
  createBrowserRouter,
  NavLink,
  RouterProvider,
  Outlet,
} from "react-router";

import Editor from "Components/admin/editor";
import ImageManager from "Components/admin/admin_image_manager";
import Inspector from "Components/admin/inspector";
import Tools from "Components/admin/tools";
import { adminEnvironment } from "Util/admin";
import { classWithModifier } from "Util/utils";

const routes: [string | undefined, string, ComponentType][] = [
  ["inspector", "🔍 Inspector", Inspector],
  [undefined, "📋 Screens Table", Editor],
  ["image-manager", "🏞️ Image Manager", ImageManager],
  ["tools", "🛠️ Tools", Tools],
];

const environment = adminEnvironment();
const isProd = environment === "prod";

const AdminHeader: ComponentType = () => (
  <header className={classWithModifier("admin-header", environment)}>
    <h1 className="admin-header__title">Screens Admin{!isProd && " Test"}</h1>
    <span className={classWithModifier("admin-header__badge", environment)}>
      {environment}
    </span>
  </header>
);

const NavLayout: ComponentType = () => (
  <>
    <AdminHeader />
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

import initSentry from "Util/sentry";
initSentry("gl_eink_single");

require("../../css/gl_eink_single.scss");

import React from "react";
import { createRoot } from "react-dom/client";
import { BrowserRouter as Router, Route, Routes } from "react-router-dom";

import ScreenContainer, {
  ScreenLayout,
} from "Components/eink/green_line/single/screen_container";

import {
  AuditScreenPage,
  MultiScreenPage,
  ScreenPage,
} from "Components/eink/screen_page";

const App = (): JSX.Element => {
  return (
    <Router>
      <Routes>
        <Route
          path="/screen/gl_eink_single"
          element={<MultiScreenPage screenContainer={ScreenContainer} />}
        />

        <Route
          path="/audit/gl_eink_single"
          element={<AuditScreenPage screenLayout={ScreenLayout} />}
        />

        <Route
          path="/screen/:id"
          element={<ScreenPage screenContainer={ScreenContainer} />}
        />
      </Routes>
    </Router>
  );
};

const container = document.getElementById("app");
const root = createRoot(container!);
root.render(<App />);

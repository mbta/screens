import initSentry from "Util/sentry";
initSentry("solari");

import initFullstory from "Util/fullstory";
initFullstory();

require("../../css/solari.scss");

import React, { useEffect } from "react";
import { createRoot } from "react-dom/client";
import { BrowserRouter as Router, Route, Routes } from "react-router-dom";

import ScreenContainer, {
  ScreenLayout,
} from "Components/solari/screen_container";

import {
  AuditScreenPage,
  MultiScreenPage,
  ScreenPage,
} from "Components/eink/screen_page";

const App = (): JSX.Element => {
  useEffect(watchdogSubscriptionEffect, []);

  return (
    <Router>
      <Routes>
        <Route
          path="/screen/solari"
          element={<MultiScreenPage screenContainer={ScreenContainer} />}
        />

        <Route
          path="/audit/solari"
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

const watchdogSubscriptionEffect = () => {
  // Add a listener for "watchdog" events
  window.addEventListener("message", handleWatchdogMessage);

  // Return a cleanup function for React to call if the component re-renders, unmounts, etc.
  return () => {
    window.removeEventListener("message", handleWatchdogMessage);
  };
};

const handleWatchdogMessage = (ev: MessageEvent) => {
  // message is formatted this way {type:"watchdog", data: counter++ }
  if (ev.data.type === "watchdog") {
    (ev?.source as Window)?.postMessage(ev.data, "*");
  }
};

const container = document.getElementById("app");
const root = createRoot(container!);
root.render(<App />);

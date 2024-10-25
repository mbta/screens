import initSentry from "Util/sentry";
initSentry("solari_large");

require("../../../css/solari_large_v2.scss");

import React from "react";
import { createRoot } from "react-dom/client";
import { BrowserRouter as Router, Route, Routes } from "react-router-dom";
import ScreenPage from "Components/v2/screen_page";
import { MappingContext } from "Components/v2/widget";

import NormalScreen from "Components/v2/solari_large/normal_screen";
import TakeoverScreen from "Components/v2/takeover_screen";
import Placeholder from "Components/v2/placeholder";
import NormalHeader from "Components/v2/lcd/normal_header";
import Departures from "Components/v2/departures";
import MultiScreenPage from "Components/v2/multi_screen_page";

const TYPE_TO_COMPONENT = {
  normal: NormalScreen,
  takeover: TakeoverScreen,
  placeholder: Placeholder,
  normal_header: NormalHeader,
  departures: Departures,
};

const App = (): JSX.Element => {
  return (
    <Router>
      <Routes>
        <Route
          path="/v2/screen/solari_large_v2"
          element={<MultiScreenPage components={TYPE_TO_COMPONENT} />}
        />

        <Route
          path="/v2/screen/:id"
          element={
            <MappingContext.Provider value={TYPE_TO_COMPONENT}>
              <ScreenPage />
            </MappingContext.Provider>
          }
        />
      </Routes>
    </Router>
  );
};

const container = document.getElementById("app");
const root = createRoot(container!);
root.render(<App />);

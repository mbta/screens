import initSentry from "Util/sentry";
initSentry("elevator");

import initFullstory from "Util/fullstory";
initFullstory();

require("../../../css/elevator_v2.scss");

import React from "react";
import { createRoot } from "react-dom/client";
import { BrowserRouter as Router, Route, Routes } from "react-router-dom";
import NormalScreen from "Components/v2/elevator/normal_screen";
import EvergreenContent from "Components/v2/evergreen_content";
import ScreenPage from "Components/v2/screen_page";
import { MappingContext } from "Components/v2/widget";
import MultiScreenPage from "Components/v2/multi_screen_page";
import ElevatorClosures from "Components/v2/elevator/elevator_closures";
import SimulationScreenPage from "Components/v2/simulation_screen_page";
import Footer from "Components/v2/elevator/footer";
import NormalHeader from "Components/v2/normal_header";

const TYPE_TO_COMPONENT = {
  normal: NormalScreen,
  elevator_closures: ElevatorClosures,
  evergreen_content: EvergreenContent,
  footer: Footer,
  normal_header: NormalHeader,
};

const App = (): JSX.Element => {
  return (
    <Router>
      <Routes>
        <Route
          path="/v2/screen/elevator_v2"
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
        <Route
          path="/v2/screen/pending?/:id/simulation"
          element={
            <MappingContext.Provider value={TYPE_TO_COMPONENT}>
              <SimulationScreenPage />
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

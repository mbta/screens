import initSentry from "Util/sentry";
initSentry("elevator");

import initFullstory from "Util/fullstory";
initFullstory();

import "../../../css/elevator_v2.scss";

import { StrictMode } from "react";
import { createRoot } from "react-dom/client";
import { BrowserRouter as Router, Route, Routes } from "react-router-dom";
import NormalScreen from "Components/v2/elevator/normal_screen";
import TakeoverScreen from "Components/v2/takeover_screen";
import EvergreenContent from "Components/v2/evergreen_content";
import ScreenPage from "Components/v2/screen_page";
import { MappingContext } from "Components/v2/widget";
import MultiScreenPage from "Components/v2/multi_screen_page";
import Closures from "Components/v2/elevator/closures";
import AlternatePath from "Components/v2/elevator/alternate_path";
import SimulationScreenPage from "Components/v2/simulation_screen_page";
import Footer from "Components/v2/elevator/footer";
import NormalHeader from "Components/v2/normal_header";
import NoData from "Components/v2/elevator/no_data";

const TYPE_TO_COMPONENT = {
  normal: NormalScreen,
  takeover: TakeoverScreen,
  elevator_closures: Closures,
  elevator_alternate_path: AlternatePath,
  evergreen_content: EvergreenContent,
  footer: Footer,
  normal_header: NormalHeader,
  no_data: NoData,
  page_load_no_data: NoData,
};

const App = (): JSX.Element => {
  return (
    <Router basename="v2/screen">
      <Routes>
        <Route
          path="elevator_v2"
          element={<MultiScreenPage components={TYPE_TO_COMPONENT} />}
        />

        <Route
          path="pending?/:id"
          element={
            <MappingContext.Provider value={TYPE_TO_COMPONENT}>
              <ScreenPage />
            </MappingContext.Provider>
          }
        />

        <Route
          path="pending?/:id/simulation"
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

const root = createRoot(document.getElementById("app")!);
root.render(
  <StrictMode>
    <App />
  </StrictMode>,
);

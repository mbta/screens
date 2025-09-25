import initSentry from "Util/sentry";
initSentry("elevator");

import initFullstory from "Util/fullstory";
initFullstory();

import "../../css/elevator.scss";

import { StrictMode } from "react";
import { createRoot } from "react-dom/client";
import { BrowserRouter as Router, Route, Routes } from "react-router-dom";
import NormalScreen from "Components/elevator/normal_screen";
import TakeoverScreen from "Components/takeover_screen";
import EvergreenContent from "Components/evergreen_content";
import ScreenPage from "Components/screen_page";
import { MappingContext } from "Components/widget";
import MultiScreenPage from "Components/multi_screen_page";
import Closures from "Components/elevator/closures";
import AlternatePath from "Components/elevator/alternate_path";
import SimulationScreenPage from "Components/simulation_screen_page";
import Footer from "Components/elevator/footer";
import NormalHeader from "Components/normal_header";
import NoData from "Components/elevator/no_data";

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
    <MappingContext.Provider value={TYPE_TO_COMPONENT}>
      <Router basename="v2/screen">
        <Routes>
          <Route path="elevator_v2" element={<MultiScreenPage />} />
          <Route path="pending?/:id" element={<ScreenPage />} />

          <Route
            path="pending?/:id/simulation"
            element={<SimulationScreenPage />}
          />
        </Routes>
      </Router>
    </MappingContext.Provider>
  );
};

const root = createRoot(document.getElementById("app")!);
root.render(
  <StrictMode>
    <App />
  </StrictMode>,
);

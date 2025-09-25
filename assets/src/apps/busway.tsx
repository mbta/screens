import initSentry from "Util/sentry";
initSentry("busway_v2");

import initFullstory from "Util/fullstory";
initFullstory();

import "../../css/busway.scss";

import { StrictMode } from "react";
import { createRoot } from "react-dom/client";
import { BrowserRouter as Router, Route, Routes } from "react-router-dom";
import ScreenPage from "Components/screen_page";
import {
  BlinkConfig,
  BlinkConfigContext,
  ResponseMapper,
  ResponseMapperContext,
} from "Components/screen_container";
import { MappingContext } from "Components/widget";

import NormalScreen from "Components/busway/normal_screen";
import TakeoverScreen from "Components/takeover_screen";

import EvergreenContent from "Components/evergreen_content";
import Placeholder from "Components/placeholder";

import NormalHeader from "Components/lcd/normal_header";
import Departures from "Components/departures";

import NoData from "Components/lcd/no_data";
import DeparturesNoData from "Components/lcd/departures_no_data";
import PageLoadNoData from "Components/lcd/page_load_no_data";

import MultiScreenPage from "Components/multi_screen_page";
import SimulationScreenPage from "Components/simulation_screen_page";

const TYPE_TO_COMPONENT = {
  normal: NormalScreen,
  takeover: TakeoverScreen,
  evergreen_content: EvergreenContent,
  placeholder: Placeholder,
  normal_header: NormalHeader,
  departures: Departures,
  no_data: NoData,
  page_load_no_data: PageLoadNoData,
  departures_no_data: DeparturesNoData,
};

const FAILURE_LAYOUT = {
  full_screen: {
    type: "no_data",
    show_alternatives: true,
  },
  type: "takeover",
};

const LOADING_LAYOUT = {
  full_screen: {
    type: "page_load_no_data",
  },
  type: "takeover",
};

const responseMapper: ResponseMapper = (apiResponse) => {
  switch (apiResponse.state) {
    case "success":
    case "simulation_success":
      return apiResponse.data;
    case "disabled":
    case "failure":
      return FAILURE_LAYOUT;
    case "loading":
      return LOADING_LAYOUT;
  }
};

const blinkConfig: BlinkConfig = {
  refreshesPerBlink: 15,
  durationMs: 34,
};

const App = (): JSX.Element => {
  return (
    <MappingContext.Provider value={TYPE_TO_COMPONENT}>
      <ResponseMapperContext.Provider value={responseMapper}>
        <BlinkConfigContext.Provider value={blinkConfig}>
          <Router basename="v2/screen">
            <Routes>
              <Route path="bus_shelter_v2" element={<MultiScreenPage />} />
              <Route path="pending?/:id" element={<ScreenPage />} />

              <Route
                path="pending?/:id/simulation"
                element={<SimulationScreenPage />}
              />
            </Routes>
          </Router>
        </BlinkConfigContext.Provider>
      </ResponseMapperContext.Provider>
    </MappingContext.Provider>
  );
};

const root = createRoot(document.getElementById("app")!);
root.render(
  <StrictMode>
    <App />
  </StrictMode>,
);

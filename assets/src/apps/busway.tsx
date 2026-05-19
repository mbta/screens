import initSentry from "Util/sentry";
initSentry("busway_v2");

import initFullstory from "Util/fullstory";
initFullstory();

import "../../css/busway.scss";

import { StrictMode, type JSX } from "react";
import { createRoot } from "react-dom/client";
import { BrowserRouter as Router, Route, Routes } from "react-router";
import ScreenPage from "Components/screen_page";
import {
  BlinkConfig,
  BlinkConfigContext,
  ResponseMapper,
  ResponseMapperContext,
} from "Components/screen_container";
import { MappingContext } from "Components/widget";

import TakeoverScreen from "Components/takeover_screen";

import BodyTakeoverDuo from "Components/lcd/body_takeover_duo";
import NormalBodyDuo from "Components/lcd/normal_body_duo";
import NormalScreen from "Components/lcd/normal_screen";
import ScreenDuoTakeover from "Components/lcd/screen_duo_takeover";
import ScreenSplitTakeover from "Components/lcd/screen_split_takeover";

import NormalBody from "Components/busway/normal_body";
import NormalBodyLeft from "Components/busway/normal_body_left";
import NormalBodyRight from "Components/busway/normal_body_right";

import EvergreenContent from "Components/evergreen_content";
import Placeholder from "Components/placeholder";

import NormalHeader from "Components/lcd/normal_header";
import Departures from "Components/departures";

import NoDataDuo from "Components/lcd/no_data_duo";
import DeparturesNoData from "Components/lcd/departures_no_data";
import PageLoadNoDataDuo from "Components/lcd/page_load_no_data_duo";

import MultiScreenPage from "Components/multi_screen_page";
import SimulationScreenPage from "Components/simulation_screen_page";

const TYPE_TO_COMPONENT = {
  // Layouts
  body_left_normal: NormalBodyLeft,
  body_normal: NormalBody,
  body_normal_duo: NormalBodyDuo,
  body_right_normal: NormalBodyRight,
  body_takeover: BodyTakeoverDuo,
  screen_normal: NormalScreen,
  screen_split_takeover: ScreenSplitTakeover,
  screen_duo_takeover: ScreenDuoTakeover,
  screen_solo_takeover: TakeoverScreen,

  // Widgets
  departures: Departures,
  departures_no_data: DeparturesNoData,
  evergreen_content: EvergreenContent,
  no_data: NoDataDuo,
  normal_header: NormalHeader,
  page_load_no_data: PageLoadNoDataDuo,
  placeholder: Placeholder,
};

const NO_DATA_LAYOUT = {
  full_duo_screen: {
    type: "no_data",
    show_alternatives: true,
  },
  type: "screen_duo_takeover",
};

const LOADING_LAYOUT = {
  full_duo_screen: {
    type: "page_load_no_data",
  },
  type: "screen_duo_takeover",
};

const responseMapper: ResponseMapper = (apiResponse) => {
  switch (apiResponse.state) {
    case "success":
    case "simulation_success":
      return apiResponse.data;
    case "disabled":
    case "failure":
      return NO_DATA_LAYOUT;
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

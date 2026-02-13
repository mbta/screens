import initSentry from "Util/sentry";
initSentry("pre_fare");

import initFullstory from "Util/fullstory";
initFullstory();

import "../../css/pre_fare.scss";

import { StrictMode, type JSX } from "react";
import { createRoot } from "react-dom/client";
import { BrowserRouter as Router, Route, Routes } from "react-router";
import ScreenPage from "Components/screen_page";
import {
  ResponseMapper,
  ResponseMapperContext,
  BlinkConfig,
  BlinkConfigContext,
  LOADING_LAYOUT,
} from "Components/screen_container";
import { MappingContext } from "Components/widget";

import Placeholder from "Components/placeholder";
import NormalScreen from "Components/pre_fare/normal_screen";
import NormalBody from "Components/pre_fare/normal_body";
import NormalBodyLeft from "Components/pre_fare/normal_body_left";
import NormalBodyRight from "Components/pre_fare/normal_body_right";
import EvergreenContent from "Components/evergreen_content";
import NormalHeader from "Components/lcd/normal_header";
import OneLarge from "Components/pre_fare/flex/one_large";
import TwoMedium from "Components/pre_fare/flex/two_medium";
import BodyLeftTakeover from "Components/pre_fare/body_left_takeover";
import BodyLeftFlex from "Components/pre_fare/body_left_flex";
import BodyRightTakeover from "Components/pre_fare/body_right_takeover";
import BodyTakeover from "Components/pre_fare/body_takeover";
import ScreenTakeover from "Components/pre_fare/screen_takeover";
import ScreenSplitTakeover from "Components/pre_fare/screen_split_takeover";
import ElevatorStatus from "Components/elevator_status";
import FullLineMap from "Components/full_line_map";
import LcdSubwayStatus from "Components/subway_status/lcd_subway_status";
import ReconstructedAlert from "Components/reconstructed_alert";
import NoData from "Components/pre_fare/no_data";
import PageLoadNoData from "Components/pre_fare/page_load_no_data";
import ReconstructedTakeover from "Components/reconstructed_takeover";
import MultiScreenPage from "Components/multi_screen_page";
import SimulationScreenPage from "Components/pre_fare/simulation_screen_page";
import PreFareSingleScreenAlert from "Components/pre_fare_single_screen_alert";
import Departures from "Components/departures";

const TYPE_TO_COMPONENT = {
  // Slots
  screen_normal: NormalScreen,
  screen_takeover: ScreenTakeover,
  screen_split_takeover: ScreenSplitTakeover,
  body_normal: NormalBody,
  body_takeover: BodyTakeover,
  body_left_normal: NormalBodyLeft,
  body_left_takeover: BodyLeftTakeover,
  body_left_flex: BodyLeftFlex,
  body_right_normal: NormalBodyRight,
  body_right_takeover: BodyRightTakeover,
  normal_header: NormalHeader,
  one_large: OneLarge,
  two_medium: TwoMedium,
  // Widgets
  placeholder: Placeholder,
  evergreen_content: EvergreenContent,
  elevator_status: ElevatorStatus,
  full_line_map: FullLineMap,
  subway_status: LcdSubwayStatus,
  no_data: NoData,
  page_load_no_data: PageLoadNoData,
  reconstructed_large_alert: ReconstructedAlert,
  single_screen_alert: PreFareSingleScreenAlert,
  reconstructed_takeover: ReconstructedTakeover,
  departures: Departures,
};

const DISABLED_LAYOUT = {
  full_screen: {
    type: "no_data",
    show_alternatives: true,
  },
  type: "screen_takeover",
};

const FAILURE_LAYOUT = DISABLED_LAYOUT;

const responseMapper: ResponseMapper = (apiResponse) => {
  switch (apiResponse.state) {
    case "success":
    case "simulation_success":
      return apiResponse.data;
    case "disabled":
      return DISABLED_LAYOUT;
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
              <Route path="pre_fare_v2" element={<MultiScreenPage />} />
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

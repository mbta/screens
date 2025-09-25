import initSentry from "Util/sentry";
initSentry("bus_shelter");

import initFullstory from "Util/fullstory";
initFullstory();

import "../../css/bus_shelter.scss";

import { StrictMode } from "react";
import { createRoot } from "react-dom/client";
import { BrowserRouter as Router, Route, Routes } from "react-router-dom";
import ScreenPage from "Components/screen_page";
import {
  ResponseMapper,
  ResponseMapperContext,
  BlinkConfig,
  BlinkConfigContext,
  AudioConfigContext,
  AudioConfig,
  LOADING_LAYOUT,
} from "Components/screen_container";
import { MappingContext } from "Components/widget";

import NormalScreen from "Components/bus_shelter/normal_screen";
import TakeoverScreen from "Components/takeover_screen";

import NormalBody from "Components/bus_shelter/normal_body";
import TakeoverBody from "Components/bus_shelter/takeover_body";

import OneLarge from "Components/bus_shelter/flex/one_large";
import OneMediumTwoSmall from "Components/bus_shelter/flex/one_medium_two_small";
import TwoMedium from "Components/bus_shelter/flex/two_medium";

import Placeholder from "Components/placeholder";
import LinkFooter from "Components/bus_shelter/link_footer";
import NormalHeader from "Components/lcd/normal_header";
import Departures from "Components/departures";
import LcdSubwayStatus from "Components/subway_status/lcd_subway_status";

import EvergreenContent from "Components/evergreen_content";
import Survey from "Components/survey";

import NoData from "Components/lcd/no_data";
import DeparturesNoData from "Components/lcd/departures_no_data";

import { FlexZoneAlert, FullBodyAlert } from "Components/bus_shelter/alert";
import MultiScreenPage from "Components/multi_screen_page";
import SimulationScreenPage from "Components/simulation_screen_page";
import { getDatasetValue } from "Util/dataset";
import PageLoadNoData from "Components/lcd/page_load_no_data";

const TYPE_TO_COMPONENT = {
  screen_normal: NormalScreen,
  screen_takeover: TakeoverScreen,
  body_normal: NormalBody,
  body_takeover: TakeoverBody,
  one_large: OneLarge,
  two_medium: TwoMedium,
  one_medium_two_small: OneMediumTwoSmall,
  placeholder: Placeholder,
  link_footer: LinkFooter,
  normal_header: NormalHeader,
  departures: Departures,
  subway_status: LcdSubwayStatus,
  alert: FlexZoneAlert,
  full_body_alert: FullBodyAlert,
  evergreen_content: EvergreenContent,
  survey: Survey,
  no_data: NoData,
  page_load_no_data: PageLoadNoData,
  departures_no_data: DeparturesNoData,
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

const getAudioConfig = (): AudioConfig | null => {
  const audioIntervalOffsetSeconds = getDatasetValue(
    "audioIntervalOffsetSeconds",
  );
  const audioReadoutInterval = getDatasetValue("audioReadoutInterval");

  if (!audioReadoutInterval || audioIntervalOffsetSeconds === undefined)
    return null;

  return {
    intervalOffsetSeconds: parseInt(audioIntervalOffsetSeconds),
    readoutIntervalMinutes: parseInt(audioReadoutInterval),
  };
};

const App = (): JSX.Element => {
  return (
    <MappingContext.Provider value={TYPE_TO_COMPONENT}>
      <ResponseMapperContext.Provider value={responseMapper}>
        <BlinkConfigContext.Provider value={blinkConfig}>
          <Router basename="v2/screen">
            <Routes>
              <Route path="bus_shelter_v2" element={<MultiScreenPage />} />

              <Route
                path="pending?/:id"
                element={
                  <AudioConfigContext.Provider value={getAudioConfig()}>
                    <ScreenPage />
                  </AudioConfigContext.Provider>
                }
              />

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

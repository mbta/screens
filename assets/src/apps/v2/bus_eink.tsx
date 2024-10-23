import initSentry from "Util/sentry";
initSentry("bus_eink_v2");

import initFullstory from "Util/fullstory";
initFullstory();

require("../../../css/bus_eink_v2.scss");

import React from "react";
import { createRoot } from "react-dom/client";
import { BrowserRouter as Router, Route, Routes } from "react-router-dom";
import ScreenPage from "Components/v2/screen_page";
import { MappingContext } from "Components/v2/widget";

import NormalScreen from "Components/v2/bus_eink/normal_screen";
import TakeoverScreen from "Components/v2/takeover_screen";
import TakeoverBody from "Components/v2/eink/takeover_body";
import NormalBody from "Components/v2/bus_eink/normal_body";
import BottomTakeoverBody from "Components/v2/bus_eink/bottom_takeover_body";
import OneMedium from "Components/v2/eink/flex/one_medium";

import Placeholder from "Components/v2/placeholder";
import NormalHeader from "Components/v2/eink/bus_normal_header";
import FareInfoFooter from "Components/v2/eink/fare_info_footer";
import Departures from "Components/v2/departures";
import EvergreenContent from "Components/v2/evergreen_content";
import {
  LOADING_LAYOUT,
  ResponseMapper,
  ResponseMapperContext,
} from "Components/v2/screen_container";
import NoData from "Components/v2/eink/no_data";
import DeparturesNoData from "Components/v2/eink/departures_no_data";
import PageLoadNoData from "Components/v2/eink/page_load_no_data";
import {
  MediumFlexAlert,
  FullBodyTopScreenAlert,
} from "Components/v2/eink/alert";
import BottomScreenFiller from "Components/v2/eink/bottom_screen_filler";
import MultiScreenPage from "Components/v2/multi_screen_page";
import SimulationScreenPage from "Components/v2/simulation_screen_page";
import DeparturesNoService from "Components/v2/eink/departures_no_service";
import EinkSubwayStatus from "Components/v2/subway_status/eink_subway_status";
import WidgetPage from "Components/v2/widget_page";
import FlexZoneTakeoverBody from "Components/v2/bus_eink/flex_zone_takeover";

const TYPE_TO_COMPONENT = {
  screen_normal: NormalScreen,
  screen_takeover: TakeoverScreen,
  body_normal: NormalBody,
  body_takeover: TakeoverBody,
  bottom_takeover: BottomTakeoverBody,
  flex_zone_takeover: FlexZoneTakeoverBody,
  one_medium: OneMedium,
  placeholder: Placeholder,
  fare_info_footer: FareInfoFooter,
  normal_header: NormalHeader,
  departures: Departures,
  alert: MediumFlexAlert,
  full_body_alert: FullBodyTopScreenAlert,
  evergreen_content: EvergreenContent,
  no_data: NoData,
  page_load_no_data: PageLoadNoData,
  bottom_screen_filler: BottomScreenFiller,
  departures_no_data: DeparturesNoData,
  departures_no_service: DeparturesNoService,
  subway_status: EinkSubwayStatus,
};

const DISABLED_LAYOUT = {
  full_screen: {
    type: "no_data",
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

const App = (): JSX.Element => {
  return (
    <Router>
      <Routes>
        <Route
          path="/v2/screen/bus_eink_v2"
          element={
            <MultiScreenPage
              components={TYPE_TO_COMPONENT}
              responseMapper={responseMapper}
            />
          }
        />

        <Route
          path="/v2/screen/pending?/:id"
          element={
            <MappingContext.Provider value={TYPE_TO_COMPONENT}>
              <ResponseMapperContext.Provider value={responseMapper}>
                <ScreenPage />
              </ResponseMapperContext.Provider>
            </MappingContext.Provider>
          }
        />

        <Route
          path="/v2/widget/bus_eink_v2"
          element={
            <MappingContext.Provider value={TYPE_TO_COMPONENT}>
              <WidgetPage />
            </MappingContext.Provider>
          }
        />

        <Route
          path="/v2/screen/pending?/:id/simulation"
          element={
            <MappingContext.Provider value={TYPE_TO_COMPONENT}>
              <ResponseMapperContext.Provider value={responseMapper}>
                <SimulationScreenPage />
              </ResponseMapperContext.Provider>
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

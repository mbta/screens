import initSentry from "Util/sentry";
initSentry("gl_eink_v2");

import initFullstory from "Util/fullstory";
initFullstory();

import "../../../css/gl_eink_v2.scss";

import { StrictMode } from "react";
import { createRoot } from "react-dom/client";
import { BrowserRouter as Router, Route, Routes } from "react-router-dom";
import ScreenPage from "Components/v2/screen_page";
import { MappingContext } from "Components/v2/widget";

import NormalScreen from "Components/v2/gl_eink/normal_screen";
import TakeoverScreen from "Components/v2/takeover_screen";
import NormalBody from "Components/v2/gl_eink/normal_body";
import TakeoverBody from "Components/v2/eink/takeover_body";
import TopTakeoverBody from "Components/v2/gl_eink/top_takeover_body";
import BottomTakeoverBody from "Components/v2/gl_eink/bottom_takeover_body";
import OneMedium from "Components/v2/eink/flex/one_medium";
import Placeholder from "Components/v2/placeholder";
import FareInfoFooter from "Components/v2/eink/fare_info_footer";
import NormalHeader from "Components/v2/eink/gl_normal_header";
import Departures from "Components/v2/departures";
import LineMap from "Components/v2/gl_eink/line_map";
import EvergreenContent from "Components/v2/evergreen_content";
import NoData from "Components/v2/eink/no_data";
import DeparturesNoData from "Components/v2/eink/departures_no_data";
import PageLoadNoData from "Components/v2/eink/page_load_no_data";
import {
  LOADING_LAYOUT,
  ResponseMapper,
  ResponseMapperContext,
} from "Components/v2/screen_container";
import {
  MediumFlexAlert,
  FullBodyTopScreenAlert,
} from "Components/v2/eink/alert";
import BottomScreenFiller from "Components/v2/eink/bottom_screen_filler";
import OvernightDepartures from "Components/v2/eink/overnight_departures";
import MultiScreenPage from "Components/v2/multi_screen_page";
import SimulationScreenPage from "Components/v2/simulation_screen_page";
import EinkSubwayStatus from "Components/v2/subway_status/eink_subway_status";
import WidgetPage from "Components/v2/widget_page";
import TopAndFlexTakeoverBody from "Components/v2/eink/top_and_flex_takeover";
import FlexZoneTakeoverBody from "Components/v2/gl_eink/flex_zone_takeover";

const TYPE_TO_COMPONENT = {
  screen_normal: NormalScreen,
  screen_takeover: TakeoverScreen,
  body_normal: NormalBody,
  body_takeover: TakeoverBody,
  top_takeover: TopTakeoverBody,
  bottom_takeover: BottomTakeoverBody,
  flex_zone_takeover: FlexZoneTakeoverBody,
  top_and_flex_takeover: TopAndFlexTakeoverBody,
  one_medium: OneMedium,
  placeholder: Placeholder,
  fare_info_footer: FareInfoFooter,
  normal_header: NormalHeader,
  departures: Departures,
  alert: MediumFlexAlert,
  full_body_alert: FullBodyTopScreenAlert,
  line_map: LineMap,
  evergreen_content: EvergreenContent,
  no_data: NoData,
  page_load_no_data: PageLoadNoData,
  bottom_screen_filler: BottomScreenFiller,
  overnight_departures: OvernightDepartures,
  departures_no_data: DeparturesNoData,
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
    <MappingContext.Provider value={TYPE_TO_COMPONENT}>
      <ResponseMapperContext.Provider value={responseMapper}>
        <Router basename="v2">
          <Routes>
            <Route path="screen/gl_eink_v2" element={<MultiScreenPage />} />
            <Route path="screen/pending?/:id" element={<ScreenPage />} />

            <Route
              path="screen/pending?/:id/simulation"
              element={<SimulationScreenPage />}
            />

            <Route path="widget/gl_eink_v2" element={<WidgetPage />} />
          </Routes>
        </Router>
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

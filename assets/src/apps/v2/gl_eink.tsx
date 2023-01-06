import initSentry from "Util/sentry";
initSentry("gl_eink_v2");

declare function require(name: string): string;
// tslint:disable-next-line
require("../../../css/gl_eink_v2.scss");

import React from "react";
import ReactDOM from "react-dom";
import { BrowserRouter as Router, Route, Switch } from "react-router-dom";
import ScreenPage from "Components/v2/screen_page";
import { MappingContext } from "Components/v2/widget";

import NormalScreen from "Components/v2/gl_eink_double/normal_screen";
import TakeoverScreen from "Components/v2/takeover_screen";
import NormalBody from "Components/v2/gl_eink_double/normal_body";
import TakeoverBody from "Components/v2/eink/takeover_body";
import TopTakeoverBody from "Components/v2/gl_eink_double/top_takeover_body";
import BottomTakeoverBody from "Components/v2/gl_eink_double/bottom_takeover_body";
import OneMedium from "Components/v2/eink/flex/one_medium";
import Placeholder from "Components/v2/placeholder";
import FareInfoFooter from "Components/v2/eink/fare_info_footer";
import NormalHeader from "Components/v2/eink/normal_header";
import NormalDepartures from "Components/v2/departures/normal_departures";
import LineMap from "Components/v2/gl_eink_double/line_map";
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
import ExceptionCatcher from "./exception_catcher";

const TYPE_TO_COMPONENT = {
  screen_normal: NormalScreen,
  screen_takeover: TakeoverScreen,
  body_normal: NormalBody,
  body_takeover: TakeoverBody,
  top_takeover: TopTakeoverBody,
  bottom_takeover: BottomTakeoverBody,
  one_medium: OneMedium,
  placeholder: Placeholder,
  fare_info_footer: FareInfoFooter,
  normal_header: NormalHeader,
  departures: NormalDepartures,
  alert: MediumFlexAlert,
  full_body_alert: FullBodyTopScreenAlert,
  line_map: LineMap,
  evergreen_content: EvergreenContent,
  no_data: NoData,
  page_load_no_data: PageLoadNoData,
  bottom_screen_filler: BottomScreenFiller,
  overnight_departures: OvernightDepartures,
  departures_no_data: DeparturesNoData,
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
      <Switch>
        <Route exact path="/v2/screen/gl_eink_v2">
          <MultiScreenPage
            components={TYPE_TO_COMPONENT}
            responseMapper={responseMapper}
          />
        </Route>
        <Route exact path="/v2/screen/:id/simulation">
          <MappingContext.Provider value={TYPE_TO_COMPONENT}>
            <ResponseMapperContext.Provider value={responseMapper}>
              <SimulationScreenPage />
            </ResponseMapperContext.Provider>
          </MappingContext.Provider>
        </Route>
        <Route path="/v2/screen/:id">
          <MappingContext.Provider value={TYPE_TO_COMPONENT}>
            <ResponseMapperContext.Provider value={responseMapper}>
              <ExceptionCatcher>
                <ScreenPage />
              </ExceptionCatcher>
            </ResponseMapperContext.Provider>
          </MappingContext.Provider>
        </Route>
      </Switch>
    </Router>
  );
};

ReactDOM.render(<App />, document.getElementById("app"));

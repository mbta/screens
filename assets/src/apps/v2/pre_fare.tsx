import initSentry from "Util/sentry";
initSentry("pre_fare");

import initFullstory from "Util/fullstory";
initFullstory();

import "../../../css/pre_fare_v2.scss";

import React from "react";
import ReactDOM from "react-dom";
import { BrowserRouter as Router, Route, Switch } from "react-router-dom";
import ScreenPage from "Components/v2/screen_page";
import {
  ResponseMapper,
  ResponseMapperContext,
  BlinkConfig,
  BlinkConfigContext,
  LOADING_LAYOUT,
} from "Components/v2/screen_container";
import { MappingContext } from "Components/v2/widget";

import Placeholder from "Components/v2/placeholder";
import NormalScreen from "Components/v2/pre_fare/normal_screen";
import NormalBody from "Components/v2/pre_fare/normal_body";
import NormalBodyLeft from "Components/v2/pre_fare/normal_body_left";
import NormalBodyRight from "Components/v2/pre_fare/normal_body_right";
import EvergreenContent from "Components/v2/evergreen_content";
import NormalHeader from "Components/v2/lcd/normal_header";
import OneLarge from "Components/v2/pre_fare/flex/one_large";
import TwoMedium from "Components/v2/pre_fare/flex/two_medium";
import BodyLeftTakeover from "Components/v2/pre_fare/body_left_takeover";
import BodyLeftFlex from "Components/v2/pre_fare/body_left_flex";
import BodyRightTakeover from "Components/v2/pre_fare/body_right_takeover";
import BodyTakeover from "Components/v2/pre_fare/body_takeover";
import ScreenTakeover from "Components/v2/pre_fare/screen_takeover";
import ScreenSplitTakeover from "Components/v2/pre_fare/screen_split_takeover";
import ElevatorStatus from "Components/v2/elevator_status";
import FullLineMap from "Components/v2/full_line_map";
import LcdSubwayStatus from "Components/v2/subway_status/lcd_subway_status";
import ReconstructedAlert from "Components/v2/reconstructed_alert";
import NoData from "Components/v2/pre_fare/no_data";
import PageLoadNoData from "Components/v2/pre_fare/page_load_no_data";
import ReconstructedTakeover from "Components/v2/reconstructed_takeover";
import CRDepartures from "Components/v2/cr_departures/cr_departures";
import OvernightCRDepartures from "Components/v2/cr_departures/overnight_cr_departures";
import MultiScreenPage from "Components/v2/multi_screen_page";
import SimulationScreenPage from "Components/v2/pre_fare/simulation_screen_page";
import PreFareSingleScreenAlert from "Components/v2/pre_fare_single_screen_alert";
import Departures from "Components/v2/departures";

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
  cr_departures: CRDepartures,
  overnight_cr_departures: OvernightCRDepartures,
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
    <Router>
      <Switch>
        <Route exact path="/v2/screen/pre_fare_v2">
          <MultiScreenPage
            components={TYPE_TO_COMPONENT}
            responseMapper={responseMapper}
          />
        </Route>
        <Route exact path={["/v2/screen/:id", "/v2/screen/pending/:id"]}>
          <MappingContext.Provider value={TYPE_TO_COMPONENT}>
            <ResponseMapperContext.Provider value={responseMapper}>
              <BlinkConfigContext.Provider value={blinkConfig}>
                <ScreenPage />
              </BlinkConfigContext.Provider>
            </ResponseMapperContext.Provider>
          </MappingContext.Provider>
        </Route>
        <Route
          exact
          path={[
            "/v2/screen/:id/simulation",
            "/v2/screen/pending/:id/simulation",
          ]}
        >
          <MappingContext.Provider value={TYPE_TO_COMPONENT}>
            <ResponseMapperContext.Provider value={responseMapper}>
              <SimulationScreenPage />
            </ResponseMapperContext.Provider>
          </MappingContext.Provider>
        </Route>
      </Switch>
    </Router>
  );
};

ReactDOM.render(<App />, document.getElementById("app"));

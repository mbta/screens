import initSentry from "Util/sentry";
initSentry("pre_fare");

declare function require(name: string): string;
// tslint:disable-next-line
require("../../../css/pre_fare_v2.scss");

import React from "react";
import ReactDOM from "react-dom";
import { BrowserRouter as Router, Route, Switch } from "react-router-dom";
import ScreenPage from "Components/v2/screen_page";
import {
  ResponseMapper,
  ResponseMapperContext,
  BlinkConfig,
  BlinkConfigContext,
} from "Components/v2/screen_container";
import { MappingContext } from "Components/v2/widget";
import Viewport from "Components/v2/pre_fare/viewport";

import Placeholder from "Components/v2/placeholder";
import NormalScreen from "Components/v2/pre_fare/normal_screen";
import NormalBody from "Components/v2/pre_fare/normal_body";
import NormalBodyLeft from "Components/v2/pre_fare/normal_body_left";
import NormalBodyRight from "Components/v2/pre_fare/normal_body_right";
import EvergreenContent from "Components/v2/evergreen_content";
import NormalHeader from "Components/v2/pre_fare/normal_header";
import OneLarge from "Components/v2/pre_fare/flex/one_large";
import TwoMedium from "Components/v2/pre_fare/flex/two_medium";
import BodyLeftTakeover from "Components/v2/pre_fare/body_left_takeover";
import BodyRightTakeover from "Components/v2/pre_fare/body_right_takeover";
import BodyTakeover from "Components/v2/pre_fare/body_takeover";
import ScreenTakeover from "Components/v2/pre_fare/screen_takeover";
import ElevatorStatus from "Components/v2/elevator_status";
import FullLineMap from "Components/v2/full_line_map";
import SubwayStatus from "Components/v2/subway_status";
import ReconstructedAlert from "Components/v2/reconstructed_alert";
import NoData from "Components/v2/pre_fare/no_data";
import ReconstructedTakeover from "Components/v2/reconstructed_takeover";
import CRDepartures from "Components/v2/cr_departures";
import MultiScreenPage from "Components/v2/multi_screen_page";
import SimulationScreenPage from "Components/v2/simulation_screen_page";
import SurgeBodyRight from "Components/v2/pre_fare/surge_body_right";

const TYPE_TO_COMPONENT = {
  screen_normal: NormalScreen,
  screen_takeover: ScreenTakeover,
  body_normal: NormalBody,
  body_takeover: BodyTakeover,
  body_left_normal: NormalBodyLeft,
  body_left_takeover: BodyLeftTakeover,
  body_right_normal: NormalBodyRight,
  body_right_surge: SurgeBodyRight,
  body_right_takeover: BodyRightTakeover,
  normal_header: NormalHeader,
  one_large: OneLarge,
  two_medium: TwoMedium,
  placeholder: Placeholder,
  evergreen_content: EvergreenContent,
  elevator_status: ElevatorStatus,
  full_line_map: FullLineMap,
  subway_status: SubwayStatus,
  no_data: NoData,
  reconstructed_large_alert: ReconstructedAlert,
  reconstructed_takeover: ReconstructedTakeover,
  cr_departures: CRDepartures
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
              <BlinkConfigContext.Provider value={blinkConfig}>
                <Viewport>
                  <ScreenPage />
                </Viewport>
              </BlinkConfigContext.Provider>
            </ResponseMapperContext.Provider>
          </MappingContext.Provider>
        </Route>
      </Switch>
    </Router>
  );
};

ReactDOM.render(<App />, document.getElementById("app"));

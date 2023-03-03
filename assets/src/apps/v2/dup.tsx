import initSentry from "Util/sentry";
initSentry("dup_v2");

declare function require(name: string): string;
// tslint:disable-next-line
require("../../../css/dup_v2.scss");

import React from "react";
import ReactDOM from "react-dom";
import { BrowserRouter as Router, Route, Switch } from "react-router-dom";
import ScreenPage from "Components/v2/screen_page";
import { MappingContext } from "Components/v2/widget";

import NormalScreen, { NormalSimulation } from "Components/v2/dup/normal_screen";
import Placeholder from "Components/v2/placeholder";
import NormalHeader from "Components/v2/dup/normal_header";
import NormalDepartures from "Components/v2/dup/departures/normal_departures";
import MultiScreenPage from "Components/v2/multi_screen_page";
import Viewport from "Components/v2/dup/viewport";
import EvergreenContent from "Components/v2/evergreen_content";
import RotationNormal from "Components/v2/dup/rotation_normal";
import RotationTakeover from "Components/v2/dup/rotation_takeover";
import NormalBody from "Components/v2/dup/normal_body";
import SplitBody from "Components/v2/dup/split_body";
import { splitRotationFromPropNames } from "Components/v2/dup/dup_rotation_wrapper";
import PartialAlert from "Components/v2/dup/partial_alert";
import TakeoverAlert from "Components/v2/dup/takeover_alert";
import SimulationScreenPage from "Components/v2/simulation_screen_page";
import { LOADING_LAYOUT, ResponseMapper, ResponseMapperContext } from "Components/v2/screen_container";

const TYPE_TO_COMPONENT = {
  screen_normal: NormalScreen,
  simulation_screen_normal: NormalSimulation,
  rotation_normal_zero: splitRotationFromPropNames(RotationNormal, "zero"),
  rotation_normal_one: splitRotationFromPropNames(RotationNormal, "one"),
  rotation_normal_two: splitRotationFromPropNames(RotationNormal, "two"),
  rotation_takeover_zero: splitRotationFromPropNames(RotationTakeover, "zero"),
  rotation_takeover_one: splitRotationFromPropNames(RotationTakeover, "one"),
  rotation_takeover_two: splitRotationFromPropNames(RotationTakeover, "two"),
  body_normal_zero: splitRotationFromPropNames(NormalBody, "zero"),
  body_normal_one: splitRotationFromPropNames(NormalBody, "one"),
  body_normal_two: splitRotationFromPropNames(NormalBody, "two"),
  body_split_zero: splitRotationFromPropNames(SplitBody, "zero"),
  body_split_one: splitRotationFromPropNames(SplitBody, "one"),
  body_split_two: splitRotationFromPropNames(SplitBody, "two"),
  placeholder: Placeholder,
  normal_header: NormalHeader,
  departures: NormalDepartures,
  evergreen_content: EvergreenContent,
  partial_alert: PartialAlert,
  takeover_alert: TakeoverAlert,
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

const App = (): JSX.Element => {
  return (
    <Router>
      <Switch>
        <Route exact path="/v2/screen/dup_v2">
          <MultiScreenPage components={TYPE_TO_COMPONENT} />
        </Route>
        <Route exact path="/v2/screen/:id/simulation">
          <MappingContext.Provider value={TYPE_TO_COMPONENT}>
            <ResponseMapperContext.Provider value={responseMapper}>
              <SimulationScreenPage opts={{alternateView: true}} />
            </ResponseMapperContext.Provider>
          </MappingContext.Provider>
        </Route>
        <Route path="/v2/screen/:id">
          <MappingContext.Provider value={TYPE_TO_COMPONENT}>
            <ResponseMapperContext.Provider value={responseMapper}>
              <Viewport>
                <ScreenPage />
              </Viewport>
            </ResponseMapperContext.Provider>
          </MappingContext.Provider>
        </Route>
      </Switch>
    </Router>
  );
};

ReactDOM.render(<App />, document.getElementById("app"));

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

import Placeholder from "Components/v2/placeholder";
import NormalScreenLeft from "Components/v2/pre_fare/normal_screen_left";
import NormalScreenRight from "Components/v2/pre_fare/normal_screen_right";
import NormalBodyRight from "Components/v2/pre_fare/normal_body_right";
import NormalHeader from "Components/v2/pre_fare/normal_header";
import TopLevelSwitch from "Components/v2/pre_fare/top_level_switch";
import OneLarge from "Components/v2/pre_fare/flex/one_large";
import TwoMedium from "Components/v2/pre_fare/flex/two_medium";
import NormalBodyLeft from "Components/v2/pre_fare/normal_body_left";
import BodyTakeoverLeft from "Components/v2/pre_fare/body_takeover_left";
import BodyTakeoverRight from "Components/v2/pre_fare/body_takeover_right";
import ScreenTakeoverLeft from "Components/v2/pre_fare/screen_takeover_left";
import ScreenTakeoverRight from "Components/v2/pre_fare/screen_takeover_right";

const TYPE_TO_COMPONENT = {
  screen_normal_left: NormalScreenLeft,
  screen_normal_right: NormalScreenRight,
  body_normal_left: NormalBodyLeft,
  body_normal_right: NormalBodyRight,
  normal_header: NormalHeader,
  top_level: TopLevelSwitch,
  one_large: OneLarge,
  two_medium: TwoMedium,
  body_takeover_left: BodyTakeoverLeft,
  body_takeover_right: BodyTakeoverRight,
  screen_takeover_left: ScreenTakeoverLeft,
  screen_takeover_right: ScreenTakeoverRight,
  placeholder: Placeholder,
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
        <Route path="/v2/screen/:id">
          <MappingContext.Provider value={TYPE_TO_COMPONENT}>
            <ResponseMapperContext.Provider value={responseMapper}>
              <BlinkConfigContext.Provider value={blinkConfig}>
                <ScreenPage />
              </BlinkConfigContext.Provider>
            </ResponseMapperContext.Provider>
          </MappingContext.Provider>
        </Route>
      </Switch>
    </Router>
  );
};

ReactDOM.render(<App />, document.getElementById("app"));

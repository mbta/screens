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
import NormalHeaderLeft from "Components/v2/pre_fare/normal_header_left";
import NormalHeaderRight from "Components/v2/pre_fare/normal_header_right";
import TopLevelSwitch from "Components/v2/pre_fare/top_level_switch";
import EvergreenContent from "Components/v2/evergreen_content";

const TYPE_TO_COMPONENT = {
  screen_normal_left: NormalScreenLeft,
  screen_normal_right: NormalScreenRight,
  placeholder: Placeholder,
  header_left: NormalHeaderLeft,
  body_normal: NormalBodyRight,
  header_right: NormalHeaderRight,
  top_level: TopLevelSwitch,
  evergreen_content: EvergreenContent,
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

declare function require(name: string): string;
// tslint:disable-next-line
require("../../../css/bus_shelter_v2.scss");

import React from "react";
import ReactDOM from "react-dom";
import { BrowserRouter as Router, Route, Switch } from "react-router-dom";
import ScreenPage from "Components/v2/screen_page";
import {
  ResponseMapper,
  ResponseMapperContext,
  BlinkConfig,
  BlinkConfigContext,
  AudioConfigContext,
  AudioConfig,
} from "Components/v2/screen_container";
import { MappingContext } from "Components/v2/widget";

import NormalScreen from "Components/v2/bus_shelter/normal_screen";
import TakeoverScreen from "Components/v2/takeover_screen";

import NormalBody from "Components/v2/bus_shelter/normal_body";
import TakeoverBody from "Components/v2/bus_shelter/takeover_body";

import OneLarge from "Components/v2/bus_shelter/flex/one_large";
import OneMediumTwoSmall from "Components/v2/bus_shelter/flex/one_medium_two_small";
import TwoMedium from "Components/v2/bus_shelter/flex/two_medium";

import Placeholder from "Components/v2/placeholder";
import LinkFooter from "Components/v2/bus_shelter/link_footer";
import NormalHeader from "Components/v2/lcd/normal_header";
import NormalDepartures from "Components/v2/departures/normal_departures";
import SubwayStatus from "Components/v2/subway_status";

import EvergreenContent from "Components/v2/evergreen_content";
import Survey from "Components/v2/survey";

import NoData from "Components/v2/bus_shelter/no_data";
import DeparturesNoData from "Components/v2/bus_shelter/departures_no_data";

import { FlexZoneAlert, FullBodyAlert } from "Components/v2/alert";

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
  departures: NormalDepartures,
  subway_status: SubwayStatus,
  alert: FlexZoneAlert,
  full_body_alert: FullBodyAlert,
  evergreen_content: EvergreenContent,
  survey: Survey,
  no_data: NoData,
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

const audioConfig: AudioConfig = {
  readoutIntervalMinutes: parseInt(document.getElementById("app").getAttribute("data-audio-readout-interval")),
  volume: parseFloat(document.getElementById("app").getAttribute("data-volume"))
}

const App = (): JSX.Element => {
  return (
    <Router>
      <Switch>
        <Route path="/v2/screen/:id">
          <MappingContext.Provider value={TYPE_TO_COMPONENT}>
            <ResponseMapperContext.Provider value={responseMapper}>
              <BlinkConfigContext.Provider value={blinkConfig}>
                <AudioConfigContext.Provider value={audioConfig}>
                  <ScreenPage />
                </AudioConfigContext.Provider>
              </BlinkConfigContext.Provider>
            </ResponseMapperContext.Provider>
          </MappingContext.Provider>
        </Route>
      </Switch>
    </Router>
  );
};

ReactDOM.render(<App />, document.getElementById("app"));

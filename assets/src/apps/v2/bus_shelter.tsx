import initSentry from "Util/sentry";
initSentry("bus_shelter");

import initFullstory from "Util/fullstory";
initFullstory();

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
  LOADING_LAYOUT,
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
import LcdSubwayStatus from "Components/v2/subway_status/lcd_subway_status";

import EvergreenContent from "Components/v2/evergreen_content";
import Survey from "Components/v2/survey";

import NoData from "Components/v2/lcd/no_data";
import DeparturesNoData from "Components/v2/lcd/departures_no_data";

import { FlexZoneAlert, FullBodyAlert } from "Components/v2/bus_shelter/alert";
import MultiScreenPage from "Components/v2/multi_screen_page";
import SimulationScreenPage from "Components/v2/simulation_screen_page";
import { getDatasetValue } from "Util/dataset";
import PageLoadNoData from "Components/v2/lcd/page_load_no_data";

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
    "audioIntervalOffsetSeconds"
  );
  const audioReadoutInterval = getDatasetValue("audioReadoutInterval");

  if (
    audioIntervalOffsetSeconds === undefined ||
    audioReadoutInterval === undefined
  ) {
    return null;
  }

  return {
    intervalOffsetSeconds: parseInt(audioIntervalOffsetSeconds),
    readoutIntervalMinutes: parseInt(audioReadoutInterval),
  };
};

const App = (): JSX.Element => {
  return (
    <Router>
      <Switch>
        <Route exact path="/v2/screen/bus_shelter_v2">
          <MultiScreenPage
            components={TYPE_TO_COMPONENT}
            responseMapper={responseMapper}
          />
        </Route>
        <Route exact path={["/v2/screen/:id", "/v2/screen/pending/:id"]}>
          <MappingContext.Provider value={TYPE_TO_COMPONENT}>
            <ResponseMapperContext.Provider value={responseMapper}>
              <BlinkConfigContext.Provider value={blinkConfig}>
                <AudioConfigContext.Provider value={getAudioConfig()}>
                  <ScreenPage />
                </AudioConfigContext.Provider>
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

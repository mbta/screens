import initSentry from "Util/sentry";
initSentry("busway_v2");

import initFullstory from "Util/fullstory";
initFullstory();

declare function require(name: string): string;
// tslint:disable-next-line
require("../../../css/busway_v2.scss");

import React from "react";
import ReactDOM from "react-dom";
import { BrowserRouter as Router, Route, Switch } from "react-router-dom";
import ScreenPage from "Components/v2/screen_page";
import {
  BlinkConfig,
  BlinkConfigContext,
  ResponseMapper,
  ResponseMapperContext,
} from "Components/v2/screen_container";
import { MappingContext } from "Components/v2/widget";

import NormalScreen from "Components/v2/busway/normal_screen";
import TakeoverScreen from "Components/v2/takeover_screen";

import Placeholder from "Components/v2/placeholder";

import NormalHeader from "Components/v2/lcd/normal_header";
import NormalDepartures from "Components/v2/departures/normal_departures";

import NoData from "Components/v2/lcd/no_data";
import DeparturesNoData from "Components/v2/lcd/departures_no_data";
import PageLoadNoData from "Components/v2/lcd/page_load_no_data";

import MultiScreenPage from "Components/v2/multi_screen_page";
import SimulationScreenPage from "Components/v2/simulation_screen_page";

const TYPE_TO_COMPONENT = {
  normal: NormalScreen,
  takeover: TakeoverScreen,
  placeholder: Placeholder,
  normal_header: NormalHeader,
  departures: NormalDepartures,
  no_data: NoData,
  page_load_no_data: PageLoadNoData,
  departures_no_data: DeparturesNoData,
};

const FAILURE_LAYOUT = {
  full_screen: {
    type: "no_data",
    show_alternatives: true,
  },
  type: "takeover",
};

const LOADING_LAYOUT = {
  full_screen: {
    type: "page_load_no_data",
  },
  type: "takeover",
};

const responseMapper: ResponseMapper = (apiResponse) => {
  switch (apiResponse.state) {
    case "success":
    case "simulation_success":
      return apiResponse.data;
    case "disabled":
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
        <Route exact path="/v2/screen/busway_v2">
          <MultiScreenPage
            components={TYPE_TO_COMPONENT}
            responseMapper={responseMapper}
          />
        </Route>
        <Route exact path="/v2/screen/:id">
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

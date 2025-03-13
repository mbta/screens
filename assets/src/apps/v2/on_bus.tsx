import initSentry from "Util/sentry";
initSentry("on_bus");

import initFullstory from "Util/fullstory";
initFullstory();

import "../../../css/on_bus_v2.scss";

import React from "react";
import ReactDOM from "react-dom";
import { BrowserRouter as Router, Route, Switch } from "react-router-dom";
import ScreenPage from "Components/v2/screen_page";
import { MappingContext } from "Components/v2/widget";
import MultiScreenPage from "Components/v2/multi_screen_page";
import SimulationScreenPage from "Components/v2/simulation_screen_page";
import Placeholder from "Components/v2/placeholder";
import NormalScreen from "Components/v2/bus_eink/normal_screen";
import NormalBody from "Components/v2/bus_eink/normal_body";
import NoData from "Components/v2/on_bus/no_data";
import {
  ResponseMapper,
  ResponseMapperContext,
} from "Components/v2/screen_container";
import { URL_PARAMS_BY_SCREEN_TYPE } from "Util/query_params";
import Departures from "Components/v2/departures";

const TYPE_TO_COMPONENT = {
  body_normal: NormalBody,
  departures: Departures,
  departures_no_data: NoData,
  no_data: NoData,
  placeholder: Placeholder,
  screen_normal: NormalScreen,
};

const LOADING_LAYOUT = {
  type: "no_data",
};

const responseMapper: ResponseMapper = (apiResponse) => {
  switch (apiResponse.state) {
    case "success":
    case "simulation_success":
      return apiResponse.data;
    case "failure":
      return LOADING_LAYOUT;
    case "loading":
      return LOADING_LAYOUT;
    case "disabled":
      return LOADING_LAYOUT;
  }
};

const App = (): JSX.Element => {
  return (
    <Router>
      <Switch>
        <Route exact path="/v2/screen/on_bus_v2">
          <MultiScreenPage
            components={TYPE_TO_COMPONENT}
            responseMapper={responseMapper}
          />
        </Route>
        <Route exact path="/v2/screen/:id">
          <MappingContext.Provider value={TYPE_TO_COMPONENT}>
            <ResponseMapperContext.Provider value={responseMapper}>
              <ScreenPage paramKeys={URL_PARAMS_BY_SCREEN_TYPE.on_bus_v2} />
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

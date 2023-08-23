declare function require(name: string): string;
// tslint:disable-next-line
require("../../../css/triptych_v2.scss");

import React from "react";
import ReactDOM from "react-dom";
import { BrowserRouter as Router, Route, Switch } from "react-router-dom";

import ScreenPage from "Components/v2/screen_page";
import { MappingContext } from "Components/v2/widget";
import {
  ResponseMapper,
  ResponseMapperContext,
  LOADING_LAYOUT,
} from "Components/v2/screen_container";

import MultiScreenPage from "Components/v2/multi_screen_page";
import SimulationScreenPage from "Components/v2/simulation_screen_page";

// Remove on go-live.
import Placeholder from "Components/v2/placeholder";

import Viewport from "Components/v2/triptych/viewport";
import NormalScreen from "Components/v2/triptych/normal_screen";
import TakeoverScreen from "Components/v2/triptych/takeover_screen";
import PageLoadNoData from "Components/v2/triptych/page_load_no_data";
import NoData from "Components/v2/triptych/no_data";

import { usePlayerName } from "Hooks/outfront";
import { isTriptych } from "Util/outfront";

const TYPE_TO_COMPONENT = {
  screen_normal: NormalScreen,
  screen_takeover: TakeoverScreen,
  placeholder: Placeholder,
  page_load_no_data: PageLoadNoData,
  no_data: NoData,
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
  if (isTriptych()) {
    const playerName = usePlayerName()!;

    return (
      <MappingContext.Provider value={TYPE_TO_COMPONENT}>
        <ResponseMapperContext.Provider value={responseMapper}>
          <Viewport>
            <ScreenPage id={playerName} />
          </Viewport>
        </ResponseMapperContext.Provider>
      </MappingContext.Provider>
    );
  }

  return (
    <Router>
      <Switch>
        <Route exact path="/v2/screen/triptych_v2">
          <MultiScreenPage
            components={TYPE_TO_COMPONENT}
            responseMapper={responseMapper}
          />
        </Route>
        <Route exact path="/v2/screen/:id/simulation">
          <MappingContext.Provider value={TYPE_TO_COMPONENT}>
            <ResponseMapperContext.Provider value={responseMapper}>
              <SimulationScreenPage opts={{ alternateView: true }} />
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

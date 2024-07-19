require("../../../css/triptych_v2.scss");

import React from "react";
import ReactDOM from "react-dom";
import { BrowserRouter as Router, Route, Switch } from "react-router-dom";

import { usePlayerName } from "Hooks/outfront";
import { isTriptych } from "Util/outfront";

import { MappingContext } from "Components/v2/widget";
import {
  ResponseMapper,
  ResponseMapperContext,
} from "Components/v2/screen_container";

import ScreenPage from "Components/v2/screen_page";
import MultiScreenPage from "Components/v2/multi_screen_page";
import SimulationScreenPage from "Components/v2/simulation_screen_page";
import Viewport from "Components/v2/triptych/viewport";

import FullScreen from "Components/v2/basic_layouts/full_screen";
import TriptychThreePane from "Components/v2/triptych/triptych_three_pane";

import PageLoadNoData from "Components/v2/triptych/page_load_no_data";
import NoData from "Components/v2/triptych/no_data";

import Placeholder from "Components/v2/placeholder";
import TrainCrowding from "Components/v2/train_crowding";
import OutfrontEvergreenContent from "Components/v2/outfront_evergreen_content";

const TYPE_TO_COMPONENT = {
  // Layouts
  screen_normal: FullScreen,
  screen_split: TriptychThreePane,
  // Components
  page_load_no_data: PageLoadNoData,
  no_data: NoData,
  train_crowding: TrainCrowding,
  evergreen_content: OutfrontEvergreenContent,
  placeholder: Placeholder,
};

const LOADING_LAYOUT = {
  full_screen: {
    type: "page_load_no_data",
  },
  type: "screen_normal",
};

const DISABLED_LAYOUT = {
  full_screen: {
    type: "no_data",
  },
  type: "screen_normal",
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
        <Route path={["/v2/screen/:id", "/v2/screen/pending/:id"]}>
          <MappingContext.Provider value={TYPE_TO_COMPONENT}>
            <ResponseMapperContext.Provider value={responseMapper}>
              <Viewport>
                <ScreenPage />
              </Viewport>
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

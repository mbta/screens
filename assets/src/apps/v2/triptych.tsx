declare function require(name: string): string;
// tslint:disable-next-line
require("../../../css/triptych_v2.scss");

import React from "react";
import ReactDOM from "react-dom";
import { BrowserRouter as Router, Route, Switch } from "react-router-dom";
import ScreenPage from "Components/v2/screen_page";
import {
  ResponseMapper,
  ResponseMapperContext,
  LOADING_LAYOUT,
} from "Components/v2/screen_container";
import { MappingContext } from "Components/v2/widget";
import { imagePath } from "Util/util";

import FullScreen from "Components/v2/basic_layouts/full_screen";
import TriptychThreePane from "Components/v2/triptych/triptych_three_pane";

import Placeholder from "Components/v2/placeholder";

import SimulationScreenPage from "Components/v2/simulation_screen_page";
import PageLoadNoData from "Components/v2/lcd/page_load_no_data";
import NoData from "Components/v2/lcd/no_data";
import TrainCrowding from "Components/v2/train_crowding";
import EvergreenContent from "Components/v2/evergreen_content";

const adjustAssetUrl = (WrappedComponent: React.ElementType) => {
  return (props: {asset_url: string}) => {
    const modifiedUrl = props.asset_url.replace("assets/static/images/", "")
    const dupReadyUrl = imagePath(modifiedUrl)
    return <WrappedComponent asset_url={dupReadyUrl} />
  }
}

const TYPE_TO_COMPONENT = {
  // Layouts
  screen_normal: FullScreen,
  screen_split: TriptychThreePane,
  // Components
  page_load_no_data: PageLoadNoData,
  no_data: NoData,
  train_crowding: TrainCrowding,
  evergreen_content: adjustAssetUrl(EvergreenContent),
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
              <ScreenPage />
            </ResponseMapperContext.Provider>
          </MappingContext.Provider>
        </Route>
      </Switch>
    </Router>
  );
};

ReactDOM.render(<App />, document.getElementById("app"));

declare function require(name: string): string;
// tslint:disable-next-line
require("../../../css/bus_eink_v2.scss");

import React from "react";
import ReactDOM from "react-dom";
import { BrowserRouter as Router, Route, Switch } from "react-router-dom";
import ScreenPage from "Components/v2/screen_page";
import { MappingContext } from "Components/v2/widget";

import NormalScreen from "Components/v2/bus_eink/normal_screen";
import TakeoverScreen from "Components/v2/takeover_screen";

import Placeholder from "Components/v2/placeholder";
import NormalHeader from "Components/v2/eink/normal_header";
import FareInfoFooter from "Components/v2/eink/fare_info_footer";
import NormalDepartures from "Components/v2/departures/normal_departures";

const TYPE_TO_COMPONENT = {
  normal: NormalScreen,
  full_takeover: TakeoverScreen,
  placeholder: Placeholder,
  fare_info_footer: FareInfoFooter,
  normal_header: NormalHeader,
  departures: NormalDepartures,
};

const App = (): JSX.Element => {
  return (
    <Router>
      <Switch>
        <Route path="/v2/screen/:id">
          <MappingContext.Provider value={TYPE_TO_COMPONENT}>
            <ScreenPage />
          </MappingContext.Provider>
        </Route>
      </Switch>
    </Router>
  );
};

ReactDOM.render(<App />, document.getElementById("app"));

import initSentry from "Util/sentry";
initSentry("solari_v2");

declare function require(name: string): string;
// tslint:disable-next-line
require("../../../css/solari_v2.scss");

import React from "react";
import ReactDOM from "react-dom";
import { BrowserRouter as Router, Route, Switch } from "react-router-dom";
import ScreenPage from "Components/v2/screen_page";
import { MappingContext } from "Components/v2/widget";

import NormalScreen from "Components/v2/solari/normal_screen";
import TakeoverScreen from "Components/v2/takeover_screen";
import Placeholder from "Components/v2/placeholder";
import NormalHeader from "Components/v2/lcd/normal_header";
import NormalDepartures from "Components/v2/departures/normal_departures";
import MultiScreenPage from "Components/v2/multi_screen_page";

const TYPE_TO_COMPONENT = {
  normal: NormalScreen,
  takeover: TakeoverScreen,
  placeholder: Placeholder,
  normal_header: NormalHeader,
  departures: NormalDepartures,
};

const App = (): JSX.Element => {
  return (
    <Router>
      <Switch>
        <Route exact path="/v2/screen/solari_v2">
          <MultiScreenPage components={TYPE_TO_COMPONENT} />
        </Route>
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

import initSentry from "Util/sentry";
initSentry("dup_v2");

declare function require(name: string): string;
// tslint:disable-next-line
require("../../../css/dup_v2.scss");

import React from "react";
import ReactDOM from "react-dom";
import { BrowserRouter as Router, Route, Switch } from "react-router-dom";
import ScreenPage from "Components/v2/screen_page";
import { MappingContext } from "Components/v2/widget";

import NormalScreen from "Components/v2/dup/normal_screen";
import TakeoverScreen from "Components/v2/takeover_screen";
import Placeholder from "Components/v2/placeholder";
import NormalHeader from "Components/v2/dup/normal_header";
import NormalDepartures from "Components/v2/departures/normal_departures";
import MultiScreenPage from "Components/v2/multi_screen_page";
import NormalBodyZero from "Components/v2/dup/normal_body_zero";
import NormalBodyOne from "Components/v2/dup/normal_body_one";
import NormalBodyTwo from "Components/v2/dup/normal_body_two";
import Viewport from "Components/v2/dup/viewport";
import ScreenTakeoverZero from "Components/v2/dup/screen_takeover_zero";
import ScreenTakeoverOne from "Components/v2/dup/screen_takeover_one";
import ScreenTakeoverTwo from "Components/v2/dup/screen_takeover_two";

const TYPE_TO_COMPONENT = {
  screen_normal: NormalScreen,
  body_normal_zero: NormalBodyZero,
  body_normal_one: NormalBodyOne,
  body_normal_two: NormalBodyTwo,
  screen_takeover_zero: ScreenTakeoverZero,
  screen_takeover_one: ScreenTakeoverOne,
  screen_takeover_two: ScreenTakeoverTwo,
  full_takeover: TakeoverScreen,
  placeholder: Placeholder,
  normal_header: NormalHeader,
  departures: NormalDepartures,
};

const App = (): JSX.Element => {
  return (
    <Router>
      <Switch>
        <Route exact path="/v2/screen/dup_v2">
          <MultiScreenPage components={TYPE_TO_COMPONENT} />
        </Route>
        <Route path="/v2/screen/:id">
          <MappingContext.Provider value={TYPE_TO_COMPONENT}>
            <Viewport>
              <ScreenPage />
            </Viewport>
          </MappingContext.Provider>
        </Route>
      </Switch>
    </Router>
  );
};

ReactDOM.render(<App />, document.getElementById("app"));

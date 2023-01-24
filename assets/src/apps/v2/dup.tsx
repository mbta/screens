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
import Placeholder from "Components/v2/placeholder";
import NormalHeader from "Components/v2/dup/normal_header";
import NormalDepartures from "Components/v2/dup/departures/normal_departures";
import MultiScreenPage from "Components/v2/multi_screen_page";
import NormalBodyZero from "Components/v2/dup/normal_body_zero";
import NormalBodyOne from "Components/v2/dup/normal_body_one";
import NormalBodyTwo from "Components/v2/dup/normal_body_two";
import Viewport from "Components/v2/dup/viewport";
import RotationNormalZero from "Components/v2/dup/rotation_normal_zero";
import RotationNormalOne from "Components/v2/dup/rotation_normal_one";
import RotationNormalTwo from "Components/v2/dup/rotation_normal_two";
import SplitBodyZero from "Components/v2/dup/split_body_zero";
import SplitBodyOne from "Components/v2/dup/split_body_one";
import SplitBodyTwo from "Components/v2/dup/split_body_two";
import RotationTakeoverZero from "Components/v2/dup/rotation_takeover_zero";
import RotationTakeoverOne from "Components/v2/dup/rotation_takeover_one";
import RotationTakeoverTwo from "Components/v2/dup/rotation_takeover_two";

const TYPE_TO_COMPONENT = {
  screen_normal: NormalScreen,
  rotation_normal_zero: RotationNormalZero,
  rotation_normal_one: RotationNormalOne,
  rotation_normal_two: RotationNormalTwo,
  rotation_takeover_zero: RotationTakeoverZero,
  rotation_takeover_one: RotationTakeoverOne,
  rotation_takeover_two: RotationTakeoverTwo,
  body_normal_zero: NormalBodyZero,
  body_normal_one: NormalBodyOne,
  body_normal_two: NormalBodyTwo,
  body_split_zero: SplitBodyZero,
  body_split_one: SplitBodyOne,
  body_split_two: SplitBodyTwo,
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

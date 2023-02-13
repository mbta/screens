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
import Viewport from "Components/v2/dup/viewport";
import RotationNormal from "Components/v2/dup/rotation_normal";
import RotationTakeover from "Components/v2/dup/rotation_takeover";
import NormalBody from "Components/v2/dup/normal_body";
import SplitBody from "Components/v2/dup/split_body";
import { splitRotationFromPropNames } from "Components/v2/dup/dup_rotation_wrapper";
import PartialAlert from "Components/v2/dup/partial_alert";
import TakeoverAlert from "Components/v2/dup/takeover_alert";

const TYPE_TO_COMPONENT = {
  screen_normal: NormalScreen,
  rotation_normal_zero: splitRotationFromPropNames(RotationNormal, "zero"),
  rotation_normal_one: splitRotationFromPropNames(RotationNormal, "one"),
  rotation_normal_two: splitRotationFromPropNames(RotationNormal, "two"),
  rotation_takeover_zero: splitRotationFromPropNames(RotationTakeover, "zero"),
  rotation_takeover_one: splitRotationFromPropNames(RotationTakeover, "one"),
  rotation_takeover_two: splitRotationFromPropNames(RotationTakeover, "two"),
  body_normal_zero: splitRotationFromPropNames(NormalBody, "zero"),
  body_normal_one: splitRotationFromPropNames(NormalBody, "one"),
  body_normal_two: splitRotationFromPropNames(NormalBody, "two"),
  body_split_zero: splitRotationFromPropNames(SplitBody, "zero"),
  body_split_one: splitRotationFromPropNames(SplitBody, "one"),
  body_split_two: splitRotationFromPropNames(SplitBody, "two"),
  placeholder: Placeholder,
  normal_header: NormalHeader,
  departures: NormalDepartures,
  partial_alert: PartialAlert,
  takeover_alert: TakeoverAlert
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

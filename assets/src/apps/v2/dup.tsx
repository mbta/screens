import initSentry from "Util/sentry";
initSentry("dup_v2");

import initFullstory from "Util/fullstory";
initFullstory();

declare function require(name: string): string;
// tslint:disable-next-line
require("../../../css/dup_v2.scss");

import React from "react";
import ReactDOM from "react-dom";
import { BrowserRouter as Router, Route, Switch } from "react-router-dom";
import ScreenPage from "Components/v2/screen_page";
import { MappingContext } from "Components/v2/widget";

import NormalScreen, {
  NormalSimulation,
} from "Components/v2/dup/normal_screen";
import NormalHeader from "Components/v2/dup/normal_header";
import NormalDepartures from "Components/v2/dup/departures/normal_departures";
import MultiScreenPage from "Components/v2/multi_screen_page";
import Viewport from "Components/v2/dup/viewport";
import EvergreenContent from "Components/v2/evergreen_content";
import RotationNormal from "Components/v2/dup/rotation_normal";
import RotationTakeover from "Components/v2/dup/rotation_takeover";
import NormalBody from "Components/v2/dup/normal_body";
import SplitBody from "Components/v2/dup/split_body";
import { splitRotationFromPropNames } from "Components/v2/dup/dup_rotation_wrapper";
import PartialAlert from "Components/v2/dup/partial_alert";
import TakeoverAlert from "Components/v2/dup/takeover_alert";
import SimulationScreenPage from "Components/v2/simulation_screen_page";
import {
  ResponseMapper,
  ResponseMapperContext,
} from "Components/v2/screen_container";
import PageLoadNoData from "Components/v2/dup/page_load_no_data";
import NoData from "Components/v2/dup/no_data";
import OvernightDepartures from "Components/v2/dup/overnight_departures";
import { usePlayerName } from "Hooks/outfront";
import { isDup } from "Util/outfront";

const TYPE_TO_COMPONENT = {
  screen_normal: NormalScreen,
  simulation_screen_normal: NormalSimulation,
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
  normal_header: NormalHeader,
  departures: NormalDepartures,
  evergreen_content: EvergreenContent,
  partial_alert: PartialAlert,
  takeover_alert: TakeoverAlert,
  page_load_no_data: PageLoadNoData,
  no_data: NoData,
  departures_no_data: NoData,
  overnight_departures: OvernightDepartures,
};

const responseMapper: ResponseMapper = (apiResponse) => {
  switch (apiResponse.state) {
    case "success":
    case "simulation_success":
      return apiResponse.data;
    case "disabled":
    case "failure":
      return {
        rotation_one: {
          full_rotation: {
            type: "no_data",
            include_header: true,
          },
          type: "rotation_takeover_one",
        },
        rotation_two: {
          full_rotation: {
            type: "no_data",
            include_header: true,
          },
          type: "rotation_takeover_two",
        },
        rotation_zero: {
          full_rotation: {
            type: "no_data",
            include_header: true,
          },
          type: "rotation_takeover_zero",
        },
        type: "screen_normal",
      };
    case "loading":
      return {
        rotation_one: {
          full_rotation: {
            type: "page_load_no_data",
          },
          type: "rotation_takeover_one",
        },
        rotation_two: {
          full_rotation: {
            type: "page_load_no_data",
          },
          type: "rotation_takeover_two",
        },
        rotation_zero: {
          full_rotation: {
            type: "page_load_no_data",
          },
          type: "rotation_takeover_zero",
        },
        type: "screen_normal",
      };
  }
};

const App = (): JSX.Element => {
  if (isDup()) {
    const playerName = usePlayerName()!;
    const id = `DUP-${playerName.trim()}`;
    return (
      <MappingContext.Provider value={TYPE_TO_COMPONENT}>
        <ResponseMapperContext.Provider value={responseMapper}>
          <Viewport>
            <ScreenPage id={id} />
          </Viewport>
        </ResponseMapperContext.Provider>
      </MappingContext.Provider>
    );
  }

  return (
    <Router>
      <Switch>
        <Route exact path="/v2/screen/dup_v2">
          <MultiScreenPage
            components={TYPE_TO_COMPONENT}
            responseMapper={responseMapper}
          />
        </Route>
        <Route exact path={["/v2/screen/:id", "/v2/screen/pending/:id"]}>
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
              <SimulationScreenPage opts={{ alternateView: true }} />
            </ResponseMapperContext.Provider>
          </MappingContext.Provider>
        </Route>
      </Switch>
    </Router>
  );
};

ReactDOM.render(<App />, document.getElementById("app"));

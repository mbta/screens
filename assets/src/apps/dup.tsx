import initSentry from "Util/sentry";
initSentry("dup_v2");

import initFullstory from "Util/fullstory";
initFullstory();

import { initFakeMRAID } from "Util/outfront";
initFakeMRAID();

import "../../css/dup.scss";

import { StrictMode, type JSX } from "react";
import { createRoot } from "react-dom/client";
import { BrowserRouter as Router, Route, Routes } from "react-router";

import ScreenPage from "Components/screen_page";
import { MappingContext } from "Components/widget";
import NormalScreen, { NormalSimulation } from "Components/dup/normal_screen";
import Placeholder from "Components/placeholder";
import NormalHeader from "Components/dup/normal_header";
import Departures from "Components/dup/departures";
import MultiScreenPage from "Components/multi_screen_page";
import Viewport from "Components/dup/viewport";
import EvergreenContent from "Components/evergreen_content";
import RotationNormal from "Components/dup/rotation_normal";
import RotationTakeover from "Components/dup/rotation_takeover";
import NormalBody from "Components/dup/normal_body";
import SplitBody from "Components/dup/split_body";
import { splitRotationFromPropNames } from "Components/dup/dup_rotation_wrapper";
import PartialAlert from "Components/dup/partial_alert";
import TakeoverAlert from "Components/dup/takeover_alert";
import SimulationScreenPage from "Components/simulation_screen_page";
import {
  ResponseMapper,
  ResponseMapperContext,
} from "Components/screen_container";
import PageLoadNoData from "Components/dup/page_load_no_data";
import NoData from "Components/dup/no_data";
import DeparturesNoData from "Components/dup/departures_no_data";
import OvernightDepartures from "Components/dup/overnight_departures";

import { Provider as CurrentPageProvider } from "Context/dup_page";
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
  placeholder: Placeholder,
  normal_header: NormalHeader,
  departures: Departures,
  evergreen_content: EvergreenContent,
  partial_alert: PartialAlert,
  takeover_alert: TakeoverAlert,
  page_load_no_data: PageLoadNoData,
  no_data: NoData,
  departures_no_data: DeparturesNoData,
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
          full_rotation: { type: "no_data" },
          type: "rotation_takeover_one",
        },
        rotation_two: {
          full_rotation: { type: "no_data" },
          type: "rotation_takeover_two",
        },
        rotation_zero: {
          full_rotation: { type: "no_data" },
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
  const playerName = usePlayerName();

  return (
    <CurrentPageProvider>
      <MappingContext.Provider value={TYPE_TO_COMPONENT}>
        <ResponseMapperContext.Provider value={responseMapper}>
          {isDup() ? (
            <Viewport>
              <ScreenPage id={`DUP-${playerName!.trim()}`} />
            </Viewport>
          ) : (
            <Router basename="v2/screen">
              <Routes>
                <Route path="dup_v2" element={<MultiScreenPage />} />

                <Route
                  path="pending?/:id"
                  element={
                    <Viewport>
                      <ScreenPage />
                    </Viewport>
                  }
                />

                <Route
                  path="pending?/:id/simulation"
                  element={
                    <SimulationScreenPage opts={{ alternateView: true }} />
                  }
                />
              </Routes>
            </Router>
          )}
        </ResponseMapperContext.Provider>
      </MappingContext.Provider>
    </CurrentPageProvider>
  );
};

const root = createRoot(document.getElementById("app")!);
root.render(
  <StrictMode>
    <App />
  </StrictMode>,
);

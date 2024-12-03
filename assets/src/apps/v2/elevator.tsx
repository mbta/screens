import initSentry from "Util/sentry";
initSentry("elevator");

import initFullstory from "Util/fullstory";
initFullstory();

require("../../../css/elevator_v2.scss");

import React from "react";
import ReactDOM from "react-dom";
import { BrowserRouter as Router, Route, Switch } from "react-router-dom";
import NormalScreen from "Components/v2/elevator/normal_screen";
import EvergreenContent from "Components/v2/evergreen_content";
import ScreenPage from "Components/v2/screen_page";
import { MappingContext } from "Components/v2/widget";
import MultiScreenPage from "Components/v2/multi_screen_page";
import OutsideElevatorClosures from "Components/v2/elevator/outside_elevator_closures";
import CurrentElevatorClosed from "Components/v2/elevator/current_elevator_closed";
import SimulationScreenPage from "Components/v2/simulation_screen_page";
import Footer from "Components/v2/elevator/footer";
import NormalHeader from "Components/v2/normal_header";

const TYPE_TO_COMPONENT = {
  normal: NormalScreen,
  outside_elevator_closures: OutsideElevatorClosures,
  current_elevator_closed: CurrentElevatorClosed,
  evergreen_content: EvergreenContent,
  footer: Footer,
  normal_header: NormalHeader,
};

const App = (): JSX.Element => {
  return (
    <Router>
      <Switch>
        <Route exact path="/v2/screen/elevator_v2">
          <MultiScreenPage components={TYPE_TO_COMPONENT} />
        </Route>
        <Route exact path="/v2/screen/:id">
          <MappingContext.Provider value={TYPE_TO_COMPONENT}>
            <ScreenPage />
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
            <SimulationScreenPage />
          </MappingContext.Provider>
        </Route>
      </Switch>
    </Router>
  );
};

ReactDOM.render(<App />, document.getElementById("app"));

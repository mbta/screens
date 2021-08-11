declare function require(name: string): string;
// tslint:disable-next-line
require("../../../css/bus_shelter_v2.scss");

import React from "react";
import ReactDOM from "react-dom";
import { BrowserRouter as Router, Route, Switch } from "react-router-dom";
import ScreenPage from "Components/v2/screen_page";
import { MappingContext } from "Components/v2/widget";

import NormalScreen from "Components/v2/bus_shelter/normal_screen";
import TakeoverScreen from "Components/v2/takeover_screen";

import NormalBody from "Components/v2/bus_shelter/normal_body";
import TakeoverBody from "Components/v2/bus_shelter/takeover_body";

import OneLarge from "Components/v2/bus_shelter/flex/one_large";
import OneMediumTwoSmall from "Components/v2/bus_shelter/flex/one_medium_two_small";
import TwoMedium from "Components/v2/bus_shelter/flex/two_medium";

import Placeholder from "Components/v2/placeholder";
import LinkFooter from "Components/v2/bus_shelter/link_footer";
import NormalHeader from "Components/v2/lcd/normal_header";
import NormalDepartures from "Components/v2/departures/normal_departures";
import SubwayStatus from "Components/v2/subway_status";

import Image from "Components/v2/evergreen/image";
import Video from "Components/v2/evergreen/video";

import { FlexZoneAlert, FullBodyAlert } from "Components/v2/alert";

const TYPE_TO_COMPONENT = {
  screen_normal: NormalScreen,
  screen_takeover: TakeoverScreen,
  body_normal: NormalBody,
  body_takeover: TakeoverBody,
  one_large: OneLarge,
  two_medium: TwoMedium,
  one_medium_two_small: OneMediumTwoSmall,
  placeholder: Placeholder,
  link_footer: LinkFooter,
  normal_header: NormalHeader,
  departures: NormalDepartures,
  subway_status: SubwayStatus,
  alert: FlexZoneAlert,
  full_body_alert: FullBodyAlert,
  evergreen_image: Image,
  evergreen_video: Video,
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

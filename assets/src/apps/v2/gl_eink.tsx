declare function require(name: string): string;
// tslint:disable-next-line
require("../../../css/gl_eink_v2.scss");

import * as Sentry from "@sentry/react";
import React from "react";
import ReactDOM from "react-dom";
import { BrowserRouter as Router, Route, Switch } from "react-router-dom";
import ScreenPage from "Components/v2/screen_page";
import { MappingContext } from "Components/v2/widget";

import NormalScreen from "Components/v2/gl_eink_double/normal_screen";
import TakeoverScreen from "Components/v2/takeover_screen";
import Placeholder from "Components/v2/placeholder";
import FareInfoFooter from "Components/v2/eink/fare_info_footer";
import NormalHeader from "Components/v2/eink/normal_header";
import NormalDepartures from "Components/v2/departures/normal_departures";
import LineMap from "Components/v2/gl_eink_double/line_map";
import EvergreenContent from "Components/v2/evergreen_content";
import NoData from "Components/v2/eink/no_data";
import { ResponseMapperContext } from "Components/v2/screen_container";
import OvernightDepartures from "Components/v2/eink/overnight_departures";

const sentryDsn = document.getElementById("app")?.dataset.sentry;
if (sentryDsn) {
  Sentry.init({
    dsn: sentryDsn,
  });
}

const TYPE_TO_COMPONENT = {
  normal: NormalScreen,
  full_takeover: TakeoverScreen,
  placeholder: Placeholder,
  fare_info_footer: FareInfoFooter,
  normal_header: NormalHeader,
  departures: NormalDepartures,
  line_map: LineMap,
  evergreen_content: EvergreenContent,
  no_data: NoData,
  overnight_departures: OvernightDepartures,
};

const DISABLED_LAYOUT = {
  full_screen: {
    type: "no_data",
  },
  type: "full_takeover",
};

const FAILURE_LAYOUT = DISABLED_LAYOUT;

const responseMapper: ResponseMapper = (apiResponse) => {
  switch (apiResponse.state) {
    case "success":
      return apiResponse.data;
    case "disabled":
      return DISABLED_LAYOUT;
    case "failure":
      return FAILURE_LAYOUT;
  }
};

const App = (): JSX.Element => {
  return (
    <Router>
      <Switch>
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

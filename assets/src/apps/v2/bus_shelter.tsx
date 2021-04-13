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

import OneLarge from "Components/v2/bus_shelter/flex/one_large";
import OneMediumTwoSmall from "Components/v2/bus_shelter/flex/one_medium_two_small";
import TwoMedium from "Components/v2/bus_shelter/flex/two_medium";

import Placeholder from "Components/v2/placeholder";
import LinkFooter from "Components/v2/link_footer";

const TYPE_TO_COMPONENT = {
  normal: NormalScreen,
  takeover: TakeoverScreen,
  one_large: OneLarge,
  two_medium: TwoMedium,
  one_medium_two_small: OneMediumTwoSmall,
  placeholder: Placeholder,
  link_footer: LinkFooter,
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

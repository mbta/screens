declare function require(name: string): string;
// tslint:disable-next-line
require("../../../css/gl_eink_single_v2.scss");

import React from "react";
import ReactDOM from "react-dom";
import { BrowserRouter as Router, Route, Switch } from "react-router-dom";
import ScreenPage from "Components/v2/screen_page";
import { MappingContext } from "Components/v2/widget";

import NormalScreen from "Components/v2/gl_eink_single/normal_screen";
import TakeoverScreen from "Components/v2/takeover_screen";
import Placeholder from "Components/v2/placeholder";
import LinkFooter from "Components/v2/eink/link_footer";
import NormalHeader from "Components/v2/eink/normal_header";
import useSentry from "Hooks/use_sentry";

const TYPE_TO_COMPONENT = {
  normal: NormalScreen,
  full_takeover: TakeoverScreen,
  placeholder: Placeholder,
  link_footer: LinkFooter,
  normal_header: NormalHeader,
};

const App = (): JSX.Element => {
  useSentry();
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

declare function require(name: string): string;
// tslint:disable-next-line
require("../../css/v2.scss");

import React from "react";
import ReactDOM from "react-dom";
import {
  BrowserRouter as Router,
  Route,
  Switch,
  useParams,
} from "react-router-dom";
import ScreenContainer from "Components/v2/screen_container";

const ScreenPage = () => {
  const { id } = useParams();
  return <ScreenContainer id={id} />;
};

const App = (): JSX.Element => {
  return (
    <Router>
      <Switch>
        <Route path="/v2/screen/:id">
          <ScreenPage />
        </Route>
      </Switch>
    </Router>
  );
};

ReactDOM.render(<App />, document.getElementById("app"));

declare function require(name: string): string;
// tslint:disable-next-line
require("../../css/v2.scss");

import React from "react";
import ReactDOM from "react-dom";

const App = (): JSX.Element => {
  return <div>(Widgets go here)</div>;
};

ReactDOM.render(<App />, document.getElementById("app"));

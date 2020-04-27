declare function require(name: string): string;
// tslint:disable-next-line
require("../../css/solari.scss");

import React from "react";
import ReactDOM from "react-dom";

const App = (): JSX.Element => {
  return <div className="test">This is a test.</div>;
};

ReactDOM.render(<App />, document.getElementById("app"));

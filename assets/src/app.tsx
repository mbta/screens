declare function require(name: string): string;
// tslint:disable-next-line
require("../css/app.scss");

import "phoenix_html";
import * as React from "react";
import ReactDOM from "react-dom";

function App(): JSX.Element {
  return <div>Hello from React!</div>;
}

ReactDOM.render(<App />, document.getElementById("app"));

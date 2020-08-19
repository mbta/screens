declare function require(name: string): string;
// tslint:disable-next-line
require("../../css/admin.scss");

import React from "react";
import ReactDOM from "react-dom";

import AdminForm from "Components/admin/admin_form";

const App = (): JSX.Element => {
  return <AdminForm />;
};

ReactDOM.render(<App />, document.getElementById("app"));

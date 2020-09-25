declare function require(name: string): string;
// tslint:disable-next-line
require("../../css/solari.scss");

import React from "react";
import ReactDOM from "react-dom";
import { BrowserRouter as Router, Route, Switch } from "react-router-dom";

import ScreenContainer, {
  ScreenLayout,
} from "Components/solari/screen_container";

import {
  AuditScreenPage,
  MultiScreenPage,
  ScreenPage,
} from "Components/eink/screen_page";

const App = (): JSX.Element => {
  console.log("Solari app is rendering");
  return (
    <MultiScreenPage screenContainer={ScreenContainer} />
  );
};

console.log("calling ReactDOM.render")
ReactDOM.render(<App />, document.getElementById("app"));

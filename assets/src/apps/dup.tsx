declare function require(name: string): string;
// tslint:disable-next-line
require("../../css/dup.scss");

import React from "react";
import ReactDOM from "react-dom";
import { BrowserRouter as Router, Route, Switch } from "react-router-dom";

import ScreenContainer, { ScreenLayout } from "Components/dup/screen_container";

import {
  AuditScreenPage,
  MultiScreenPage,
  ScreenPage,
} from "Components/eink/screen_page";

const App = (): JSX.Element => {
  return (
    <ScreenContainer id={"401"} />
  )
};

ReactDOM.render(<App />, document.getElementById("app"));

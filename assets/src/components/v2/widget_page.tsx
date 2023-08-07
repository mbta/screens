import { getDatasetValue } from "Util/dataset";
import React from "react";
import Widget from "./widget";

const WidgetPage = () => {
  const widgetJson = JSON.parse(getDatasetValue("widgetData"))

  return widgetJson ? <Widget data={widgetJson} /> : null
};

export default WidgetPage;

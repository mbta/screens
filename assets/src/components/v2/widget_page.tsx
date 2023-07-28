import { getDatasetValue } from "Util/dataset";
import React from "react";
import Widget from "./widget";

const WidgetPage = () => {
  const widget = getDatasetValue("widgetData")
  let widgetJson = widget ? JSON.parse(widget) : null
  if (widgetJson) widgetJson = Object.values(widgetJson)[0]

  return widgetJson ? <Widget data={widgetJson} /> : null
};

export default WidgetPage;

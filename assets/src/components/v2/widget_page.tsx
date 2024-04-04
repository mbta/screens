import { getDatasetValue } from "Util/dataset";
import React from "react";
import Widget from "./widget";

const WidgetPage = () => {
  const widgetData = getDatasetValue("widgetData");
  return widgetData ? <Widget data={JSON.parse(widgetData)} /> : null;
};

export default WidgetPage;

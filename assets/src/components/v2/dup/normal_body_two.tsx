import React from "react";

import Widget, { WidgetData } from "Components/v2/widget";

interface Props {
  header: WidgetData;
  main_content_secondary: WidgetData;
  inline_alert: WidgetData;
}

const NormalBodyTwo: React.ComponentType<Props> = ({
  header,
  main_content_secondary: mainContentSecondary,
  inline_alert: inlineAlert,
}) => {
  return (
    <div className="body-normal">
      <div className="widget-slot body-normal__header">
        <Widget data={header} />
      </div>
      <div className="widget-slot body-normal__main-content">
        <Widget data={mainContentSecondary} />
      </div>
      <div className="widget-slot body-normal__inline-alert">
        <Widget data={inlineAlert} />
      </div>
    </div>
  );
};

export default NormalBodyTwo;

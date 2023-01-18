import React from "react";

import Widget, { WidgetData } from "Components/v2/widget";

interface Props {
  header_two: WidgetData;
  main_content_secondary_two: WidgetData;
  inline_alert_two: WidgetData;
}

const NormalBodyTwo: React.ComponentType<Props> = ({
  header_two: header,
  main_content_secondary_two: mainContentSecondary,
  inline_alert_two: inlineAlert,
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

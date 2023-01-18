import React from "react";

import Widget, { WidgetData } from "Components/v2/widget";

interface Props {
  header_zero: WidgetData;
  main_content_primary_zero: WidgetData;
  inline_alert_zero: WidgetData;
}

const NormalBodyZero: React.ComponentType<Props> = ({
  header_zero: header,
  main_content_primary_zero: mainContentPrimary,
  inline_alert_zero: inlineAlert,
}) => {
  return (
    <div className="body-normal">
      <div className="widget-slot body-normal__header">
        <Widget data={header} />
      </div>
      <div className="widget-slot body-normal__main-content">
        <Widget data={mainContentPrimary} />
      </div>
      <div className="widget-slot body-normal__inline-alert">
        <Widget data={inlineAlert} />
      </div>
    </div>
  );
};

export default NormalBodyZero;

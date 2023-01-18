import React from "react";

import Widget, { WidgetData } from "Components/v2/widget";

interface Props {
  header_one: WidgetData;
  main_content_primary_one: WidgetData;
}

const NormalBodyOne: React.ComponentType<Props> = ({
  header_one: header,
  main_content_primary_one: mainContentPrimary,
}) => {
  return (
    <div className="body-normal">
      <div className="widget-slot body-normal__header">
        <Widget data={header} />
      </div>
      <div className="widget-slot body-normal__main-content">
        <Widget data={mainContentPrimary} />
      </div>
    </div>
  );
};

export default NormalBodyOne;

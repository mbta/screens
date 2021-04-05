import React from "react";

import Widget, { WidgetData } from "Components/v2/widget";

interface Props {
  header_normal: WidgetData;
  main_content_normal: WidgetData;
}

const NormalScreen: React.ComponentType<Props> = ({
  header_normal: header,
  main_content_normal: mainContent,
}) => {
  return (
    <div className="screen-normal">
      <div className="screen-normal__header">
        <Widget data={header} />
      </div>
      <div className="screen-normal__main-content">
        <Widget data={mainContent} />
      </div>
    </div>
  );
};

export default NormalScreen;

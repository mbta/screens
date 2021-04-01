import React from "react";

import Widget, { WidgetData } from "Components/v2/widget";

interface Props {
  header: WidgetData;
  main_content: WidgetData;
  footer: WidgetData;
}

const NormalScreen: React.ComponentType<Props> = ({
  header,
  main_content: mainContent,
  footer,
}) => {
  return (
    <div className="screen-normal">
      <div className="screen-normal__header">
        <Widget data={header} />
      </div>
      <div className="screen-normal__main-content">
        <Widget data={mainContent} />
      </div>
      <div className="screen-normal__footer">
        <Widget data={footer} />
      </div>
    </div>
  );
};

export default NormalScreen;

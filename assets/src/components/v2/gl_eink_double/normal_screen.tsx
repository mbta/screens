import React from "react";

import Widget, { WidgetData } from "Components/v2/widget";

interface Props {
  header: WidgetData;
  main_content: WidgetData;
  medium_flex: WidgetData;
  footer: WidgetData;
}

const NormalScreen: React.ComponentType<Props> = ({
  header,
  footer,
  main_content: mainContent,
  medium_flex: mediumFlex,
}) => {
  return (
    <div className="screen-normal">
      <div className="screen-normal__header">
        <Widget data={header} />
      </div>
      <div className="screen-normal__main-content">
        <Widget data={mainContent} />
      </div>
      <div className="screen-normal__medium-flex">
        <Widget data={mediumFlex} />
      </div>
      <div className="screen-normal__footer">
        <Widget data={footer} />
      </div>
    </div>
  );
};

export default NormalScreen;

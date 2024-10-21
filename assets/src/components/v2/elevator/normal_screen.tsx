import React from "react";

import Widget, { WidgetData } from "Components/v2/widget";

interface Props {
  header: WidgetData;
  main_content: WidgetData;
  footer: WidgetData;
}

const NormalScreen = ({ header, main_content: mainContent, footer }: Props) => {
  return (
    <div className="screen-normal">
      <div className="screen-normal__header">
        <Widget data={header} />
      </div>
      <div className="screen-normal__body">
        <Widget data={mainContent} />
      </div>
      <div className="screen-normal__footer">
        <Widget data={footer} />
      </div>
    </div>
  );
};

export default NormalScreen;

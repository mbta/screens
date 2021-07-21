import React from "react";

import Widget, { WidgetData } from "Components/v2/widget";

interface Props {
  main_content: WidgetData;
  flex_zone: WidgetData;
  footer: WidgetData;
}

const NormalBody: React.ComponentType<Props> = ({
  main_content: mainContent,
  flex_zone: flexZone,
  footer,
}) => {
  return (
    <div className="body-normal">
      <div className="body-normal__main-content">
        <Widget data={mainContent} />
      </div>
      <div className="body-normal__flex-zone">
        <Widget data={flexZone} />
      </div>
      <div className="body-normal__footer">
        <Widget data={footer} />
      </div>
    </div>
  );
};

export default NormalBody;

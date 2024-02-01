import React from "react";

import Widget, { WidgetData } from "Components/v2/widget";

interface Props {
  main_content: WidgetData;
  flex_zone_takeover: WidgetData;
  footer: WidgetData;
}

const FlexZoneTakeoverBody: React.ComponentType<Props> = ({
  footer,
  main_content: mainContent,
  flex_zone_takeover: flexZoneTakeover,
}) => {
  return (
    <div className="flex-zone-takeover">
      <div className="flex-zone-takeover__main-content">
        <Widget data={mainContent} />
      </div>
      <div className="flex-zone-takeover__flex-zone">
        <Widget data={flexZoneTakeover} />
      </div>
      <div className="flex-zone-takeover__footer">
        <Widget data={footer} />
      </div>
    </div>
  );
};

export default FlexZoneTakeoverBody;

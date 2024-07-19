import React from "react";

import Widget, { WidgetData } from "Components/v2/widget";

interface Props {
  left_sidebar: WidgetData;
  main_content: WidgetData;
  flex_zone_takeover: WidgetData;
  footer: WidgetData;
}

const FlexZoneTakeoverBody: React.ComponentType<Props> = ({
  left_sidebar: leftSidebar,
  main_content: mainContent,
  flex_zone_takeover: flexZoneTakeover,
  footer,
}) => {
  return (
    <div className="body-flex-zone-takeover">
      <div className="body-flex-zone-takeover__left-sidebar">
        <Widget data={leftSidebar} />
      </div>
      <div className="body-flex-zone-takeover__main-content">
        <Widget data={mainContent} />
      </div>
      <div className="body-flex-zone-takeover__flex-zone">
        <Widget data={flexZoneTakeover} />
      </div>
      <div className="body-flex-zone-takeover__footer">
        <Widget data={footer} />
      </div>
    </div>
  );
};

export default FlexZoneTakeoverBody;

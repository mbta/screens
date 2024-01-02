import React from "react";

import Widget, { WidgetData } from "Components/v2/widget";

interface Props {
  full_body_top_screen: WidgetData;
  flex_zone_takeover: WidgetData;
  footer: WidgetData;
}

const TopAndFlexTakeoverBody: React.ComponentType<Props> = ({
  full_body_top_screen: fullBodyTopScreen,
  flex_zone_takeover: flexZoneTakeover,
  footer,
}) => {
  return (
    <div className="body-top-and-flex-takeover">
      <div className="body-top-and-flex__top-screen">
        <Widget data={fullBodyTopScreen} />
      </div>
      <div className="body-top-and-flex__flex-zone">
        <Widget data={flexZoneTakeover} />
      </div>
      <div className="body-top-and-flex__footer">
        <Widget data={footer} />
      </div>
    </div>
  );
};

export default TopAndFlexTakeoverBody;

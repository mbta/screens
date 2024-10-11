import React from "react";

import Widget, { WidgetData } from "Components/v2/widget";

interface Props {
  full_body_top_screen: WidgetData;
  main_content: WidgetData;
  flex_zone: WidgetData;
  footer: WidgetData;
}

const TopTakeoverBody: React.ComponentType<Props> = ({
  full_body_top_screen: fullBodyTopScreen,
  flex_zone: flexZone,
  footer,
}) => {
  return (
    <div className="body-top-takeover">
      <div className="body-top-takeover__top-screen">
        <Widget data={fullBodyTopScreen} />
      </div>
      <div className="body-top-takeover__flex-zone">
        <Widget data={flexZone} />
      </div>
      <div className="body-top-takeover__footer">
        <Widget data={footer} />
      </div>
    </div>
  );
};

export default TopTakeoverBody;

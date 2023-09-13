import React from "react";

import Widget, { WidgetData } from "Components/v2/widget";

interface Props {
  full_main_content: WidgetData;
  main_content: WidgetData;
  flex_zone: WidgetData;
  footer: WidgetData;
}

const TopTakeoverBody: React.ComponentType<Props> = ({
  full_main_content: fullMainContent,
  flex_zone: flexZone,
  footer,
}) => {
  return (
    <div className="body-top-takeover">
      <div className="body-top-takeover__top-screen">
        <Widget data={fullMainContent} />
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

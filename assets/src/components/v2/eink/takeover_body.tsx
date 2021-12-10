import React from "react";

import Widget, { WidgetData } from "Components/v2/widget";

interface Props {
  full_body_top_screen: WidgetData;
  full_body_bottom_screen: WidgetData;
}

const TakeoverBody: React.ComponentType<Props> = ({
  full_body_top_screen: fullBodyTopScreen,
  full_body_bottom_screen: fullBodyBottomScreen,
}) => {
  return (
    <div className="body-takeover">
      <div className="body-takeover__top-screen">
        <Widget data={fullBodyTopScreen} />
      </div>
      <div className="body-takeover__bottom-screen">
        <Widget data={fullBodyBottomScreen} />
      </div>
    </div>
  );
};

export default TakeoverBody;

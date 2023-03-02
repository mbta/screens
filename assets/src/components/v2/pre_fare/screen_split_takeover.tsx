import React from "react";

import Widget, { WidgetData } from "Components/v2/widget";

interface Props {
  full_left_screen: WidgetData;
  full_right_screen: WidgetData;
}

const ScreenSplitTakeover: React.ComponentType<Props> = ({
  full_left_screen: fullLeftScreen,
  full_right_screen: fullRightScreen,
}) => {
  return (
    <div className="screen-split-takeover">
      <div className="screen-split-takeover__full-left-screen">
        <Widget data={fullLeftScreen} />
      </div>
      <div className="screen-split-takeover__full-right-screen">
        <Widget data={fullRightScreen} />
      </div>
    </div>
  );
};

export default ScreenSplitTakeover;

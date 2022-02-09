import React from "react";

import Widget, { WidgetData } from "Components/v2/widget";

interface Props {
  full_screen_right: WidgetData;
}

const ScreenTakeoverRight: React.ComponentType<Props> = ({
  full_screen_right: fullScreenRight,
}) => {
  return (
    <div className="screen-takeover-right">
      <div className="screen-takeover-right__full-screen">
        <Widget data={fullScreenRight} />
      </div>
    </div>
  );
};

export default ScreenTakeoverRight;

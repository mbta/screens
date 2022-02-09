import React from "react";

import Widget, { WidgetData } from "Components/v2/widget";

interface Props {
  full_screen_left: WidgetData;
}

const ScreenTakeoverLeft: React.ComponentType<Props> = ({
  full_screen_left: fullScreenLeft,
}) => {
  return (
    <div className="screen-takeover-left">
      <div className="screen-takeover-left__full-screen">
        <Widget data={fullScreenLeft} />
      </div>
    </div>
  );
};

export default ScreenTakeoverLeft;

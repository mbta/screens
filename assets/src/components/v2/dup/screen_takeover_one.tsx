import React from "react";

import Widget, { WidgetData } from "Components/v2/widget";

interface Props {
  full_screen_one: WidgetData;
}

const ScreenTakeoverOne: React.ComponentType<Props> = ({
  full_screen_one: fullScreenOne,
}) => {
  return (
    <div className="screen-takeover">
      <div className="widget-slot screen-takeover__rotation-one">
        <Widget data={fullScreenOne} />
      </div>
    </div>
  );
};

export default ScreenTakeoverOne;

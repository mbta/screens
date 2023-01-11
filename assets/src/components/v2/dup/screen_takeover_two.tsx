import React from "react";

import Widget, { WidgetData } from "Components/v2/widget";

interface Props {
  full_screen_two: WidgetData;
}

const ScreenTakeoverTwo: React.ComponentType<Props> = ({
  full_screen_two: fullScreenTwo,
}) => {
  return (
    <div className="screen-takeover">
      <div className="screen-takeover__rotation-two">
        <Widget data={fullScreenTwo} />
      </div>
    </div>
  );
};

export default ScreenTakeoverTwo;

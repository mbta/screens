import React from "react";

import Widget, { WidgetData } from "Components/v2/widget";

interface Props {
  full_screen_zero: WidgetData;
}

const ScreenTakeoverZero: React.ComponentType<Props> = ({
  full_screen_zero: fullScreenZero,
}) => {
  return (
    <div className="screen-takeover">
      <div className="screen-takeover__rotation-zero">
        <Widget data={fullScreenZero} />
      </div>
    </div>
  );
};

export default ScreenTakeoverZero;

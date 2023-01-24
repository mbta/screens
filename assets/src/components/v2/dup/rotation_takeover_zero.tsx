import React from "react";

import Widget, { WidgetData } from "Components/v2/widget";

interface Props {
  full_rotation_zero: WidgetData;
}

const RotationTakeoverZero: React.ComponentType<Props> = ({
  full_rotation_zero: fullRotation,
}) => {
  return (
    <div className="widget-slot rotation-zero">
      <div className="widget-slot rotation-takeover">
        <Widget data={fullRotation} />
      </div>
    </div>
  );
};

export default RotationTakeoverZero;

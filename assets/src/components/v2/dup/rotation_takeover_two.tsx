import React from "react";

import Widget, { WidgetData } from "Components/v2/widget";

interface Props {
  full_rotation_two: WidgetData;
}

const RotationTakeoverTwo: React.ComponentType<Props> = ({
  full_rotation_two: fullRotation,
}) => {
  return (
    <div className="widget-slot rotation-two">
      <div className="widget-slot rotation-takeover">
        <Widget data={fullRotation} />
      </div>
    </div>
  );
};

export default RotationTakeoverTwo;

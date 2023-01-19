import React from "react";

import Widget, { WidgetData } from "Components/v2/widget";

interface Props {
  full_rotation_one: WidgetData;
}

const RotationTakeoverOne: React.ComponentType<Props> = ({
  full_rotation_one: fullRotation,
}) => {
  return (
    <div className="rotation-one">
      <div className="widget-slot rotation-takeover">
        <Widget data={fullRotation} />
      </div>
    </div>
  );
};

export default RotationTakeoverOne;

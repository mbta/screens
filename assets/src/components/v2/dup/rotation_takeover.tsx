import type { ComponentType } from "react";
import Widget, { WidgetData } from "Components/v2/widget";

interface Props {
  full_rotation: WidgetData;
  rotation: string;
}

const RotationTakeover: ComponentType<Props> = ({
  full_rotation: fullRotation,
  rotation: rotation,
}) => {
  return (
    <div className={`widget-slot rotation-${rotation}`}>
      <div className="widget-slot rotation-takeover">
        <Widget data={fullRotation} />
      </div>
    </div>
  );
};

export default RotationTakeover;

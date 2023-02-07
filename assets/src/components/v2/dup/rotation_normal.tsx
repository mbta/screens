import React from "react";

import Widget, { WidgetData } from "Components/v2/widget";

interface Props {
  header: WidgetData;
  body: WidgetData;
  rotation: string;
}

const RotationNormal: React.ComponentType<Props> = ({
  header: header,
  body: body,
  rotation: rotation
}) => {
  return (
    <div className={`widget-slot rotation-${rotation}`}>
      <div className="widget-slot rotation-normal__header">
        <Widget data={header} />
      </div>
      <div className="widget-slot rotation-normal__body">
        <Widget data={body} />
      </div>
    </div>
  );
};

export default RotationNormal;

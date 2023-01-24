import React from "react";

import Widget, { WidgetData } from "Components/v2/widget";

interface Props {
  header_zero: WidgetData;
  body_zero: WidgetData;
}

const RotationNormalZero: React.ComponentType<Props> = ({
  header_zero: header,
  body_zero: body,
}) => {
  return (
    <div className="widget-slot rotation-zero">
      <div className="widget-slot rotation-normal__header">
        <Widget data={header} />
      </div>
      <div className="widget-slot rotation-normal__body">
        <Widget data={body} />
      </div>
    </div>
  );
};

export default RotationNormalZero;

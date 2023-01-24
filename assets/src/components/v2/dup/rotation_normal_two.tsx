import React from "react";

import Widget, { WidgetData } from "Components/v2/widget";

interface Props {
  header_two: WidgetData;
  body_two: WidgetData;
}

const RotationNormalTwo: React.ComponentType<Props> = ({
  header_two: header,
  body_two: body,
}) => {
  return (
    <div className="widget-slot rotation-two">
      <div className="widget-slot rotation-normal__header">
        <Widget data={header} />
      </div>
      <div className="widget-slot rotation-normal__body">
        <Widget data={body} />
      </div>
    </div>
  );
};

export default RotationNormalTwo;

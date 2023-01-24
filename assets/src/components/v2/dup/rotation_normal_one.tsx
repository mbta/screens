import React from "react";

import Widget, { WidgetData } from "Components/v2/widget";

interface Props {
  header_one: WidgetData;
  body_one: WidgetData;
}

const RotationNormalOne: React.ComponentType<Props> = ({
  header_one: header,
  body_one: body,
}) => {
  return (
    <div className="widget-slot rotation-one">
      <div className="widget-slot rotation-normal__header">
        <Widget data={header} />
      </div>
      <div className="widget-slot rotation-normal__body">
        <Widget data={body} />
      </div>
    </div>
  );
};

export default RotationNormalOne;

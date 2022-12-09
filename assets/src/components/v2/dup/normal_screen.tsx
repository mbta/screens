import React from "react";

import Widget, { WidgetData } from "Components/v2/widget";

interface Props {
  header_normal: WidgetData;
  rotation_zero: WidgetData;
  rotation_one: WidgetData;
  rotation_two: WidgetData;
}

const NormalScreen: React.ComponentType<Props> = ({
  rotation_zero: rotationZero,
  rotation_one: rotationOne,
  rotation_two: rotationTwo,
}) => {
  return (
    <div className="screen-normal">
      <div className="screen-normal__rotation-zero">
        <Widget data={rotationZero} />
      </div>
      <div className="screen-normal__rotation-one">
        <Widget data={rotationOne} />
      </div>
      <div className="screen-normal__rotation-two">
        <Widget data={rotationTwo} />
      </div>
    </div>
  );
};

export default NormalScreen;

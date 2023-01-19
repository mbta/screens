import React from "react";

import Widget, { WidgetData } from "Components/v2/widget";

interface Props {
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
      <Widget data={rotationZero} />
      <Widget data={rotationOne} />
      <Widget data={rotationTwo} />
    </div>
  );
};

export default NormalScreen;

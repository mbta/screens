import React from "react";

import Widget, { WidgetData } from "Components/v2/widget";

interface Props {
  header_right: WidgetData;
  body: WidgetData;
}

const NormalScreenRight: React.ComponentType<Props> = ({
  header_right,
  body,
}) => {
  return (
    <div className="screen-normal">
      <div className="screen-normal__header">
        <Widget data={header_right} />
      </div>
      <div className="screen-normal__body">
        <Widget data={body} />
      </div>
    </div>
  );
};

export default NormalScreenRight;

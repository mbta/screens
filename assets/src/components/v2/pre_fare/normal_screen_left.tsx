import React from "react";

import Widget, { WidgetData } from "Components/v2/widget";

interface Props {
  header_left: WidgetData;
  main_content_left: WidgetData;
}

const NormalScreenLeft: React.ComponentType<Props> = ({
  header_left,
  main_content_left,
}) => {
  return (
    <div className="screen-normal">
      <div className="screen-normal__header">
        <Widget data={header_left} />
      </div>
      <div className="screen-normal__body">
        <Widget data={main_content_left} />
      </div>
    </div>
  );
};

export default NormalScreenLeft;

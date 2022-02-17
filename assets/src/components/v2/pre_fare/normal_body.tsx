import React from "react";

import Widget, { WidgetData } from "Components/v2/widget";

interface Props {
  body_left: WidgetData;
  body_right: WidgetData;
}

const NormalBody: React.ComponentType<Props> = ({
  body_left: bodyLeft,
  body_right: bodyRight,
}) => {
  return (
    <div className="body-normal">
      <div className="body-normal__left">
        <Widget data={bodyLeft} />
      </div>
      <div className="body-normal__right">
        <Widget data={bodyRight} />
      </div>
    </div>
  );
};

export default NormalBody;

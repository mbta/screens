import React from "react";

import Widget, { WidgetData } from "Components/v2/widget";

interface Props {
  full_body_right: WidgetData;
}

const BodyTakeoverRight: React.ComponentType<Props> = ({
  full_body_right: fullBodyRight,
}) => {
  return (
    <div className="body-takeover-right">
      <div className="body-takeover-right__full-body">
        <Widget data={fullBodyRight} />
      </div>
    </div>
  );
};

export default BodyTakeoverRight;

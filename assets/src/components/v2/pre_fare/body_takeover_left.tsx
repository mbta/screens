import React from "react";

import Widget, { WidgetData } from "Components/v2/widget";

interface Props {
  full_body_left: WidgetData;
}

const BodyTakeoverLeft: React.ComponentType<Props> = ({
  full_body_left: fullBodyLeft,
}) => {
  return (
    <div className="body-takeover-left">
      <div className="body-takeover-left__full-body">
        <Widget data={fullBodyLeft} />
      </div>
    </div>
  );
};

export default BodyTakeoverLeft;

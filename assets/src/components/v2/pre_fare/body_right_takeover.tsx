import React from "react";

import Widget, { WidgetData } from "Components/v2/widget";

interface Props {
  full_body_right: WidgetData;
}

const BodyRightTakeover: React.ComponentType<Props> = ({
  full_body_right: fullBodyRight,
}) => {
  return (
    <div className="body-right-takeover">
      <div className="body-right-takeover__full-body">
        <Widget data={fullBodyRight} />
      </div>
    </div>
  );
};

export default BodyRightTakeover;

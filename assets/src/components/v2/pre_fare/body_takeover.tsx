import React from "react";

import Widget, { WidgetData } from "Components/v2/widget";

interface Props {
  full_body: WidgetData;
}

const BodyTakeover: React.ComponentType<Props> = ({
  full_body: fullBody,
}) => {
  return (
    <div className="body-takeover">
      <div className="body-takeover__full-body">
        <Widget data={fullBody} />
      </div>
    </div>
  );
};

export default BodyTakeover;

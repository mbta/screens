import React from "react";

import Widget, { WidgetData } from "Components/v2/widget";

interface Props {
  fullscreen: WidgetData;
}

const Takeover: React.ComponentType<Props> = ({ fullscreen }) => {
  return (
    <div className="screen-takeover">
      <div className="screen-takeover__fullscreen">
        <Widget data={fullscreen} />
      </div>
    </div>
  );
};

export default Takeover;

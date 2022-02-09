import React from "react";

import Widget, { WidgetData } from "Components/v2/widget";

interface Props {
  large: WidgetData;
}

const OneLarge: React.ComponentType<Props> = ({ large }) => {
  return (
    <div className="flex-one-large">
      <div className="flex-one-large__large">
        <Widget data={large} />
      </div>
    </div>
  );
};

export default OneLarge;

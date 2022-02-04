import React, { useEffect, useState } from "react";

import Widget, { WidgetData } from "Components/v2/widget";

interface Props {
  upper_right: WidgetData;
  lower_right: WidgetData;
}

const NormalBodyRight: React.ComponentType<Props> = ({
  upper_right: upperRight,
  lower_right: lowerRight,
}) => {
  return (
    <div className="body-normal-right">
      <div className="body-normal-right__secondary-content">
        <Widget data={upperRight} />
      </div>
      <div className="body-normal-right__main-content">
        <Widget data={lowerRight} />
      </div>
    </div>
  );
};

export default NormalBodyRight;

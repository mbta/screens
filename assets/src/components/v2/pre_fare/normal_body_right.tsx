import React from "react";

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
    <div className="body-right-normal">
      <div className="body-right-normal__upper">
        <Widget data={upperRight} />
      </div>
      <div className="body-right-normal__lower">
        <Widget data={lowerRight} />
      </div>
    </div>
  );
};

export default NormalBodyRight;

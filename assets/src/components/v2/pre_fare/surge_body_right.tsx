import React from "react";

import Widget, { WidgetData } from "Components/v2/widget";

interface Props {
  orange_line_surge_upper: WidgetData;
  orange_line_surge_lower: WidgetData;
}

const SurgeBodyRight: React.ComponentType<Props> = ({
  orange_line_surge_upper: orangeLineSurgeUpper,
  orange_line_surge_lower: orangeLineSurgeLower,
}) => {
  return (
    <div className="body-right-surge">
      <div className="body-right-surge__upper">
        <Widget data={orangeLineSurgeUpper} />
      </div>
      <div className="body-right-surge__lower">
        <Widget data={orangeLineSurgeLower} />
      </div>
    </div>
  );
};

export default SurgeBodyRight;

import React from "react";

import Widget, { WidgetData } from "Components/v2/widget";

interface Props {
  medium_left: WidgetData;
  medium_right: WidgetData;
  page_index: number;
  num_pages: number;
}

const TwoMedium: React.ComponentType<Props> = ({
  medium_left: mediumLeft,
  medium_right: mediumRight,
  page_index: pageIndex,
  num_pages: numPages,
}) => {
  return (
    <div className="flex-two-medium">
      <div className="flex-two-medium__left">
        <Widget data={mediumLeft} />
      </div>
      <div className="flex-two-medium__right">
        <Widget data={mediumRight} />
      </div>
    </div>
  );
};

export default TwoMedium;

import React from "react";

import Widget, { WidgetData } from "Components/v2/widget";
import FlexZonePageIndicator from "Components/v2/flex/page_indicator";

interface Props {
  medium_left: WidgetData;
  medium_right: WidgetData;
  page_index: number;
  num_pages: number;
}

const TwoMedium: React.ComponentType<Props> = ({
  medium_left: mediumLeft,
  medium_right: mediumRight,
  num_pages: numPages,
  page_index: pageIndex,
}) => {
  return (
    <div className="flex-two-medium">
      <div className="flex-two-medium__left">
        <Widget data={mediumLeft} />
      </div>
      <div className="flex-two-medium__right">
        <Widget data={mediumRight} />
      </div>
      <FlexZonePageIndicator numPages={numPages} pageIndex={pageIndex} />
    </div>
  );
};

export default TwoMedium;

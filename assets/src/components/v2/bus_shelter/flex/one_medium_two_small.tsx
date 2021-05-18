import React from "react";

import Widget, { WidgetData } from "Components/v2/widget";
import FlexZonePageIndicator from "Components/v2/bus_shelter/flex/page_indicator";

interface Props {
  medium_left: WidgetData;
  small_upper_right: WidgetData;
  small_lower_right: WidgetData;
  page_index: number;
  num_pages: number;
}

const OneMediumTwoSmall: React.ComponentType<Props> = ({
  medium_left: mediumLeft,
  small_upper_right: smallUpperRight,
  small_lower_right: smallLowerRight,
  num_pages: numPages,
  page_index: pageIndex,
}) => {
  return (
    <div className="flex-one-medium-two-small">
      <div className="flex-one-medium-two-small__left">
        <Widget data={mediumLeft} />
      </div>
      <div className="flex-one-medium-two-small__upper-right">
        <Widget data={smallUpperRight} />
      </div>
      <div className="flex-one-medium-two-small__lower-right">
        <Widget data={smallLowerRight} />
      </div>
      <FlexZonePageIndicator pageIndex={pageIndex} numPages={numPages} />
    </div>
  );
};

export default OneMediumTwoSmall;

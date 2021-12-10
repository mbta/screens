import React from "react";

import Widget, { WidgetData } from "Components/v2/widget";
import FlexZonePageIndicator from "Components/v2/flex/page_indicator";

interface Props {
  medium: WidgetData;
  page_index: number;
  num_pages: number;
}

const OneMedium: React.ComponentType<Props> = ({
  medium,
  num_pages: numPages,
  page_index: pageIndex,
}) => {
  return (
    <div className="flex-one-medium">
      <div className="flex-one-medium__medium">
        <Widget data={medium} />
      </div>
      <FlexZonePageIndicator pageIndex={pageIndex} numPages={numPages} />
    </div>
  );
};

export default OneMedium;

import React from "react";

import Widget, { WidgetData } from "Components/v2/widget";
import FlexZonePageIndicator from "Components/v2/flex/page_indicator";

interface Props {
  large: WidgetData;
  page_index: number;
  num_pages: number;
}

const OneLarge: React.ComponentType<Props> = ({
  large,
  num_pages: numPages,
  page_index: pageIndex,
}) => {
  console.log(numPages);
  return (
    <div className="flex-one-large">
      <div className="flex-one-large__large">
        <Widget data={large} />
      </div>
      <FlexZonePageIndicator numPages={numPages} pageIndex={pageIndex} />
    </div>
  );
};

export default OneLarge;

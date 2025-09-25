import type { ComponentType } from "react";
import Widget, { WidgetData } from "Components/widget";
import FlexZonePageIndicator from "Components/flex/page_indicator";

interface Props {
  large: WidgetData;
  page_index: number;
  num_pages: number;
}

const OneLarge: ComponentType<Props> = ({
  large,
  num_pages: numPages,
  page_index: pageIndex,
}) => {
  return (
    <div className="flex-one-large">
      <div className="flex-one-large__large">
        <Widget data={large} />
      </div>
      <FlexZonePageIndicator pageIndex={pageIndex} numPages={numPages} />
    </div>
  );
};

export default OneLarge;

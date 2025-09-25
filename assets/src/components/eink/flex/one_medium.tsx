import type { ComponentType } from "react";
import Widget, { WidgetData } from "Components/widget";
import FlexZonePageIndicator from "Components/flex/page_indicator";

interface Props {
  medium: WidgetData;
  page_index: number;
  num_pages: number;
}

const OneMedium: ComponentType<Props> = ({
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

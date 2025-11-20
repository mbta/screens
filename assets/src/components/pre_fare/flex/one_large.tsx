import type { ComponentType } from "react";
import FlexZonePageIndicator from "Components/flex/page_indicator";
import Widget, { WidgetData } from "Components/widget";

interface Props {
  large: WidgetData;
  num_pages: number;
  page_index: number;
}

const OneLarge: ComponentType<Props> = ({ large, num_pages, page_index }) => {
  return (
    <div className="flex-one-large">
      <div className="flex-one-large__large">
        <Widget data={large} />
      </div>
      <FlexZonePageIndicator numPages={num_pages} pageIndex={page_index} />
    </div>
  );
};

export default OneLarge;

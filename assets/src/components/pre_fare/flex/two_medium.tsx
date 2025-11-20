import type { ComponentType } from "react";
import FlexZonePageIndicator from "Components/flex/page_indicator";
import Widget, { WidgetData } from "Components/widget";

interface Props {
  medium_left: WidgetData;
  medium_right: WidgetData;
  num_pages: number;
  page_index: number;
}

const TwoMedium: ComponentType<Props> = ({
  medium_left: mediumLeft,
  medium_right: mediumRight,
  num_pages,
  page_index,
}) => {
  return (
    <div className="flex-two-medium">
      <div className="flex-two-medium__left">
        <Widget data={mediumLeft} />
      </div>
      <div className="flex-two-medium__right">
        <Widget data={mediumRight} />
      </div>
      <FlexZonePageIndicator numPages={num_pages} pageIndex={page_index} />
    </div>
  );
};

export default TwoMedium;

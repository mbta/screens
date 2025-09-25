import type { ComponentType } from "react";
import Widget, { WidgetData } from "Components/widget";

interface Props {
  paged_main_content_left: WidgetData;
}

const BodyLeftFlex: ComponentType<Props> = ({
  paged_main_content_left: pagedMainContentLeft,
}) => {
  return (
    <div className="body-left-flex">
      <div className="body-left-flex__paged-main-content">
        <Widget data={pagedMainContentLeft} />
      </div>
    </div>
  );
};

export default BodyLeftFlex;

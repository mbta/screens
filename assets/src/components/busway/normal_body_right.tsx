import type { ComponentType } from "react";
import Widget, { WidgetData } from "Components/widget";

interface Props {
  main_content_right: WidgetData;
}

const NormalBodyRight: ComponentType<Props> = ({
  main_content_right: mainContentRight,
}) => {
  return (
    <div className="body-right-normal">
      <div className="body-right-normal__main-content">
        <Widget data={mainContentRight} />
      </div>
    </div>
  );
};

export default NormalBodyRight;

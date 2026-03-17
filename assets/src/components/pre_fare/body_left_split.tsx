import type { ComponentType } from "react";
import Widget, { WidgetData } from "Components/widget";

interface Props {
  body_left_top: WidgetData;
  body_left_bottom: WidgetData;
}

const BodyLeftSplit: ComponentType<Props> = ({
  body_left_top: bodyLeftTop,
  body_left_bottom: bodyLeftBottom,
}) => {
  return (
    <div className="body-left-split">
      <div className="body-left-top">
        <Widget data={bodyLeftTop} />
      </div>
      <div className="body-left-bottom">
        <Widget data={bodyLeftBottom} />
      </div>
    </div>
  );
};

export default BodyLeftSplit;

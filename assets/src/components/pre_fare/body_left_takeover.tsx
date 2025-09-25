import type { ComponentType } from "react";
import Widget, { WidgetData } from "Components/widget";

interface Props {
  full_body_left: WidgetData;
}

const BodyLeftTakeover: ComponentType<Props> = ({
  full_body_left: fullBodyLeft,
}) => {
  return (
    <div className="body-left-takeover">
      <div className="body-left-takeover__full-body">
        <Widget data={fullBodyLeft} />
      </div>
    </div>
  );
};

export default BodyLeftTakeover;

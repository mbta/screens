import type { ComponentType } from "react";
import Widget, { WidgetData } from "Components/v2/widget";

interface Props {
  full_body_duo: WidgetData;
}

const BodyTakeover: ComponentType<Props> = ({ full_body_duo: fullBodyDuo }) => {
  return (
    <div className="body-takeover">
      <div className="body-takeover__full-body">
        <Widget data={fullBodyDuo} />
      </div>
    </div>
  );
};

export default BodyTakeover;

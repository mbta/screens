import type { ComponentType } from "react";
import Widget, { WidgetData } from "Components/widget";

interface Props {
  full_body: WidgetData;
}

const TakeoverBody: ComponentType<Props> = ({ full_body: fullBody }) => {
  return (
    <div className="body-takeover">
      <div className="body-takeover__full-body">
        <Widget data={fullBody} />
      </div>
    </div>
  );
};

export default TakeoverBody;

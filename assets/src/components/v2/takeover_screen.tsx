import type { ComponentType } from "react";
import Widget, { WidgetData } from "Components/v2/widget";

interface Props {
  full_screen: WidgetData;
}

const TakeoverScreen: ComponentType<Props> = ({ full_screen: fullScreen }) => {
  return (
    <div className="screen-takeover">
      <div className="screen-takeover__full-screen">
        <Widget data={fullScreen} />
      </div>
    </div>
  );
};

export default TakeoverScreen;

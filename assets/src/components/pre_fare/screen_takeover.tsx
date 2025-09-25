import type { ComponentType } from "react";
import Widget, { WidgetData } from "Components/widget";

interface Props {
  full_duo_screen: WidgetData;
}

const ScreenTakeover: ComponentType<Props> = ({
  full_duo_screen: fullDuoScreen,
}) => {
  return (
    <div className="screen-takeover">
      <div className="screen-takeover__full-duo-screen">
        <Widget data={fullDuoScreen} />
      </div>
    </div>
  );
};

export default ScreenTakeover;

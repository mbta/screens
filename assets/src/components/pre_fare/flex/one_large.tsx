import type { ComponentType } from "react";
import Widget, { WidgetData } from "Components/widget";

interface Props {
  large: WidgetData;
}

const OneLarge: ComponentType<Props> = ({ large }) => {
  return (
    <div className="flex-one-large">
      <div className="flex-one-large__large">
        <Widget data={large} />
      </div>
    </div>
  );
};

export default OneLarge;

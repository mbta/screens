import type { ComponentType } from "react";
import Widget, { WidgetData } from "Components/widget";

interface Props {
  upper_right: WidgetData;
  lower_right: WidgetData;
}

const NormalBodyRight: ComponentType<Props> = ({
  upper_right: upperRight,
  lower_right: lowerRight,
}) => {
  return (
    <div className="body-right-normal">
      <div className="body-right-normal__upper">
        <Widget data={upperRight} />
      </div>
      <div className="body-right-normal__lower">
        <Widget data={lowerRight} />
      </div>
    </div>
  );
};

export default NormalBodyRight;

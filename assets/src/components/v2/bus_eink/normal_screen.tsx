import type { ComponentType } from "react";
import Widget, { WidgetData } from "Components/v2/widget";

interface Props {
  header: WidgetData;
  body: WidgetData;
}

const NormalScreen: ComponentType<Props> = ({ header, body }) => {
  return (
    <div className="screen-normal">
      <div className="screen-normal__header">
        <Widget data={header} />
      </div>
      <div className="screen-normal__body">
        <Widget data={body} />
      </div>
    </div>
  );
};

export default NormalScreen;

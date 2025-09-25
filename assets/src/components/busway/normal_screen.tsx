import type { ComponentType } from "react";
import Widget, { WidgetData } from "Components/widget";

interface Props {
  header: WidgetData;
  main_content: WidgetData;
}

const NormalScreen: ComponentType<Props> = ({
  header: header,
  main_content: mainContent,
}) => {
  return (
    <div className="screen-normal">
      <div className="screen-normal__header">
        <Widget data={header} />
      </div>
      <div className="screen-normal__main-content">
        <Widget data={mainContent} />
      </div>
    </div>
  );
};

export default NormalScreen;

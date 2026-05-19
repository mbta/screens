import type { ComponentType } from "react";
import Widget, { WidgetData } from "Components/widget";

interface Props {
  main_content: WidgetData;
}

const NormalBody: ComponentType<Props> = ({ main_content: mainContent }) => {
  return (
    <div className="body-normal">
      <div className="body-normal__main-content">
        <Widget data={mainContent} />
      </div>
    </div>
  );
};

export default NormalBody;

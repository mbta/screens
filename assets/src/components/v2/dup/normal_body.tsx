import React from "react";

import Widget, { WidgetData } from "Components/v2/widget";

interface Props {
  main_content: WidgetData;
  // Rotation is added via the wrapper, but it's not used for this component
  rotation: string;
}

const NormalBody: React.ComponentType<Props> = ({
  main_content: mainContent,
}) => {
  return (
    <div className="body-normal">
      <div className="widget-slot body-normal__main-content">
        <Widget data={mainContent} />
      </div>
    </div>
  );
};

export default NormalBody;

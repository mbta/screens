import React from "react";

import Widget, { WidgetData } from "Components/v2/widget";

interface Props {
  main_content_reduced: WidgetData;
  bottom_pane: WidgetData;
  // Rotation is added via the wrapper, but it's not used for this component
  rotation: string;
}

const SplitBody: React.ComponentType<Props> = ({
  main_content_reduced: mainContentReduced,
  bottom_pane: bottomPane,
}) => {
  return (
    <div className="body-split">
      <div className="widget-slot body-split__main-content-reduced">
        <Widget data={mainContentReduced} />
      </div>
      <div className="widget-slot body-split__bottom-pane">
        <Widget data={bottomPane} />
      </div>
    </div>
  );
};

export default SplitBody;

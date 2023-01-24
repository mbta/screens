import React from "react";

import Widget, { WidgetData } from "Components/v2/widget";

interface Props {
  main_content_reduced_one: WidgetData;
  bottom_pane_one: WidgetData;
}

const SplitBodyOne: React.ComponentType<Props> = ({
  main_content_reduced_one: mainContentReduced,
  bottom_pane_one: bottomPane,
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

export default SplitBodyOne;

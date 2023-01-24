import React from "react";

import Widget, { WidgetData } from "Components/v2/widget";

interface Props {
  main_content_reduced_zero: WidgetData;
  bottom_pane_zero: WidgetData;
}

const SplitBodyZero: React.ComponentType<Props> = ({
  main_content_reduced_zero: mainContentReduced,
  bottom_pane_zero: bottomPane,
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

export default SplitBodyZero;

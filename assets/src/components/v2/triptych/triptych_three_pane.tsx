import React from "react";

import Widget, { WidgetData } from "Components/v2/widget";

interface Props {
  left_pane: WidgetData;
  middle_pane: WidgetData;
  right_pane: WidgetData;
}

const TriptychThreePane: React.ComponentType<Props> = ({
  left_pane: leftPane,
  middle_pane: middlePane,
  right_pane: rightPane
}) => {
  return (
    <div className="three-flex-panes">
      <div className="left-pane">
        <Widget data={leftPane} />
      </div>
      <div className="middle-pane">
        <Widget data={middlePane} />
      </div>
      <div className="right-pane">
        <Widget data={rightPane} />
      </div>
    </div>
  );
};

export default TriptychThreePane;

import React from "react";

import Widget, { WidgetData } from "Components/v2/widget";
import { TriptychPane, getTriptychPane } from "Util/outfront";

interface Props {
  left_pane: WidgetData;
  middle_pane: WidgetData;
  right_pane: WidgetData;
}

const isInViewport = (pane: TriptychPane | null, slotPosition: TriptychPane) =>
  pane == null || pane == slotPosition;

const TriptychThreePane: React.ComponentType<Props> = ({
  left_pane: leftPane,
  middle_pane: middlePane,
  right_pane: rightPane,
}) => {
  const pane = getTriptychPane();

  return (
    <>
      <div className="left-pane">
        {isInViewport(pane, "left") && <Widget data={leftPane} />}
      </div>
      <div className="middle-pane">
        {isInViewport(pane, "middle") && <Widget data={middlePane} />}
      </div>
      <div className="right-pane">
        {isInViewport(pane, "right") && <Widget data={rightPane} />}
      </div>
    </>
  );
};

export default TriptychThreePane;

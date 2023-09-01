import React from "react";
import Widget, { WidgetData } from "../widget";

interface Props {
  left_pane?: WidgetData;
  middle_pane?: WidgetData;
  right_pane?: WidgetData;
  full_screen?: WidgetData;
}

const NormalSimulation: React.ComponentType<Props> = ({
  left_pane,
  middle_pane,
  right_pane,
  full_screen,
}) => {
  if (left_pane && middle_pane && right_pane) {
    return (
      <div className="simulation-three-flex-panes">
        <div className="left-pane">
          <Widget data={left_pane} />
        </div>
        <div className="middle-pane">
          <Widget data={middle_pane} />
        </div>
        <div className="right-pane">
          <Widget data={right_pane} />
        </div>
      </div>
    );
  } else if (full_screen) {
    return (
      <div className="simulation-full-screen">
        <Widget data={full_screen} />
      </div>
    );
  }
  return <div />;
};

export default NormalSimulation;

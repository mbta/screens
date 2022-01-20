import React from "react";

import Widget, { WidgetData } from "Components/v2/widget";
import { useLocation } from "react-router-dom";

interface Props {
  left: WidgetData;
  right: WidgetData;
}

type ScreenSide = "left" | "right";

const TopLevelSwitch: React.ComponentType<Props> = ({ left, right }) => {
  const query = new URLSearchParams(useLocation().search);
  const screenSide: ScreenSide = query.get("screen_side") as ScreenSide;

  switch (screenSide) {
    case "left":
      return (
        <div className="left-screen">
          <Widget data={left} />
        </div>
      );
    case "right":
      return (
        <div className="right-screen">
          <Widget data={right} />
        </div>
      );
  }
};

export default TopLevelSwitch;

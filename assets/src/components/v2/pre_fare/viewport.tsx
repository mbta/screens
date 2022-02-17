import React from "react";

import { useLocation } from "react-router-dom";

type ScreenSide = "left" | "right";

/**
 * Shifts either the left or right side of the screen content into
 * view, based on a `screen_side` query param.
 * If the param is missing, this will show the full
 * screen content (2160px x 1920px).
 */
const Viewport: React.ComponentType<{}> = ({ children }) => {
  const query = new URLSearchParams(useLocation().search);
  const screenSide: ScreenSide | null = query.get("screen_side") as ScreenSide;

  let viewportClassName = "pre-fare-screen-viewport";
  let shifterClassName = "pre-fare-shifter";
  switch (screenSide) {
    case "left":
      shifterClassName += " pre-fare-shifter--left";
      break;
    case "right":
      shifterClassName += " pre-fare-shifter--right";
      break;
    default:
      viewportClassName += " pre-fare-screen-viewport--both";
  }

  return (
    <div className={viewportClassName}>
      <div className={shifterClassName}>
        {children}
      </div>
    </div>
  );
};

export default Viewport;

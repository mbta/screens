import React from "react";

import { getScreenSide } from "Util/util";

/**
 * Shifts either the left or right side of the screen content into
 * view, based on a `data-screen-side` data attribute on the #app div.
 * If the param is missing, this will show the full
 * screen content (2160px x 1920px).
 */
const Viewport: React.ComponentType<{}> = ({ children }) => {
  let viewportClassName = "pre-fare-screen-viewport";
  let shifterClassName = "pre-fare-shifter";
  switch (getScreenSide()) {
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

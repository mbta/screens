import React from "react";

import { getRotationIndex } from "Util/util";

/**
 * Shifts either the left or right side of the screen content into
 * view, based on a `data-screen-side` data attribute on the #app div.
 * If the param is missing, this will show the full
 * screen content (2160px x 1920px).
 */
const Viewport: React.ComponentType<{}> = ({ children }) => {
  let viewportClassName = "dup-screen-viewport";
  let shifterClassName = "dup-shifter";
  switch (getRotationIndex()) {
    case "0":
      shifterClassName += " dup-shifter--rotation-zero";
      break;
    case "1":
      shifterClassName += " dup-shifter--rotation-one";
      break;
    case "2":
      shifterClassName += " dup-shifter--rotation-two";
      break;
    default:
      viewportClassName += " dup-screen-viewport--both";
  }

  return (
    <div className={viewportClassName}>
      <div className={shifterClassName}>{children}</div>
    </div>
  );
};

export default Viewport;

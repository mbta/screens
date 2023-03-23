import React from "react";

import { getRotationIndex } from "Util/util";

/**
 * Shifts one of the three rotations into view
 * based on a `data-rotation-index` data attribute on the #app div.
 * If the param is missing, this will show the full
 * screen content (5760px x 1080px).
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
      viewportClassName += " dup-screen-viewport--all";
  }

  return (
    <div className={viewportClassName}>
      <div className={shifterClassName}>{children}</div>
    </div>
  );
};

export default Viewport;

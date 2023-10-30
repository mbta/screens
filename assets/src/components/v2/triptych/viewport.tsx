import React from "react";

import { getTriptychPane } from "Util/outfront";

/**
 * Shifts one of the three triptych panes into view
 * based on a `data-triptych-pane` data attribute on the #app div.
 * If the param is missing, this will show the full
 * screen content (3240px x 1920px).
 */
const Viewport: React.ComponentType<{}> = ({ children }) => {
  let viewportClassName = "triptych-screen-viewport";
  let shifterClassName = "triptych-shifter";

  const pane = getTriptychPane();
  if (pane != null) {
    shifterClassName += ` triptych-shifter--${pane}`;
  } else {
    viewportClassName += " triptych-screen-viewport--all";
  }

  return (
    <div className={viewportClassName}>
      <div className={shifterClassName}>{children}</div>
    </div>
  );
};

export default Viewport;

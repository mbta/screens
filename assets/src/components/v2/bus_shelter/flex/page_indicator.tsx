import React from "react";

import { classWithModifier } from "Util/util";

const FlexZonePageIndicator = ({ pageIndex, numPages }) => {
  return (
    <div className="flex-zone-page-indicator">
      {Array.from({ length: numPages }).map((_, i) => {
        const modifier = i === pageIndex ? "selected" : "unselected";

        return (
          <div
            className={classWithModifier(
              "flex-zone-page-indicator__page",
              modifier
            )}
            key={i}
          ></div>
        );
      })}
    </div>
  );
};

export default FlexZonePageIndicator;

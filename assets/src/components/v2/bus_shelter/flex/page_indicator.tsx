import React from "react";

import { classWithModifier } from "Util/util";

const FlexZonePageIndicator = ({ pageIndex, numPages }) => {
  return (
    <div className="flex-zone-page-indicator">
      {Array.from({ length: numPages }).map((_, i) => {
        let modifier;
        if (i < pageIndex) {
          modifier = "past";
        } else if (i == pageIndex) {
          modifier = "selected";
        } else {
          modifier = "unselected";
        }

        return (
          <div
            className={classWithModifier(
              "flex-zone-page-indicator__page",
              modifier
            )}
            key={i}
          >
            <div className="flex-zone-page-indicator__page__progress-bar" />
          </div>
        );
      })}
    </div>
  );
};

export default FlexZonePageIndicator;

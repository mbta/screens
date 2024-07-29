import React, { ComponentType } from "react";

import NoConnection from "Images/svgr_bundled/live-data-none.svg";
import FreeText, { FreeTextType } from "Components/v2/free_text";

interface NoDataSection {
  text: FreeTextType;
}

const NoDataSection: ComponentType<NoDataSection> = ({ text }) => {
  return (
    <div className="departures-section no-data-section">
      <div className="no-data-section__row">
        <FreeText lines={text} />
        <div className="no-data-section__icon-container">
          <NoConnection
            width="128"
            height="128"
            className="no-data-section__no-connection-icon"
            color="#171F26"
          />
        </div>
      </div>
    </div>
  );
};

export default NoDataSection;

import React from "react";

import NoConnection from "../../../../../static/images/svgr_bundled/live-data-none.svg";
import FreeText from "Components/v2/free_text";

const NoDataSection = ({ text }) => {
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

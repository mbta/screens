import React from "react";

import NoConnection from "Components/v2/bundled_svg/no_connection";
import FreeText from "Components/v2/free_text";

const NoDataSection = ({ text }) => {
  return (
    <div className="departures-section no-data-section">
      <div className="no-data-section__row">
        <FreeText lines={text} />
        <div className="no-data-section__icon-container">
          <NoConnection
            className="no-data-section__no-connection-icon"
            colorHex="#171F26"
          />
        </div>
      </div>
    </div>
  );
};

export default NoDataSection;

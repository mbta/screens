import React from "react";

import FreeText from "Components/v2/dup/dup_free_text";
import NoConnection from "Components/v2/bundled_svg/no_connection";

const NoDataSection = ({ text }) => {
  return (
    <div className="departures-section no-data-section">
      <div className="no-data-section__row">
        <FreeText lines={text} />
        <NoConnection
          className="no-data-section__no-connection-icon"
          colorHex="#171F26"
        />
      </div>
    </div>
  );
};

export default NoDataSection;

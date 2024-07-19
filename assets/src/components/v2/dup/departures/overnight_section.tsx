import React from "react";

import FreeText from "Components/v2/free_text";

const OvernightSection = ({ text }) => {
  return (
    <div className="departures-section overnight-section">
      <div className="overnight-section__row">
        <FreeText lines={text} />
      </div>
    </div>
  );
};

export default OvernightSection;

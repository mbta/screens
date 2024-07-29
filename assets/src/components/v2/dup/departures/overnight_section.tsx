import React, { ComponentType } from "react";

import FreeText, { FreeTextType } from "Components/v2/free_text";

interface OvernightSection {
  text: FreeTextType;
}

const OvernightSection: ComponentType<OvernightSection> = ({ text }) => {
  return (
    <div className="departures-section overnight-section">
      <div className="overnight-section__row">
        <FreeText lines={text} />
      </div>
    </div>
  );
};

export default OvernightSection;

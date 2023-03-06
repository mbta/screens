import React from "react";
import FreeText from "Components/v2/dup/dup_free_text";

const HeadwaySection = ({ text, isOnlySection }) => {
  const className = isOnlySection ? "full-screen-headway" : "partial-alert";

  return (
    <div className="headway-section">
      <div className={className}>
        <FreeText lines={text} />
      </div>
    </div>
  );
};

export default HeadwaySection;

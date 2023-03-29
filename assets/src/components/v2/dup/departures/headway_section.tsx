import React from "react";
import FreeText from "Components/v2/free_text";

const HeadwaySection = ({ text }) => {
  return (
    <div className="departures-section headway-section">
      <FreeText lines={text} />
    </div>
  );
};

export default HeadwaySection;

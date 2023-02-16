import React from "react";
import FreeText from "Components/v2/dup/dup_free_text";
import LinkArrow from "../bundled_svg/link_arrow";

const HeadwaySection = ({ text, isOnlySection }) => {
  const className = isOnlySection ? "full-screen-alert-text" : "partial-alert";

  return (
    <div className="headway-section">
      <div className={className}>
        <FreeText lines={text} />
      </div>
      <div className="headway-section__link">
        <div className="headway-section__link-arrow">
          <LinkArrow width={375} colorHex="#a2a3a3" />
        </div>
        <div className="headway-section__link-text">mbta.com/schedules</div>
      </div>
    </div>
  );
};

export default HeadwaySection;

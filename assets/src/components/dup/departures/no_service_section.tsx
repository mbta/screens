import type { ComponentType } from "react";

import FreeText, { FreeTextType } from "Components/free_text";
import InfoIcon from "Images/info.svg";

interface NoServiceSection {
  text: FreeTextType;
}

const NoServiceSection: ComponentType<NoServiceSection> = ({ text }) => {
  return (
    <div className="departures-section no-service-section">
      <div className="no-service-section__row">
        <FreeText lines={text} />
        <div className="no-service-section__icon-container">
          <InfoIcon
            width="128"
            height="128"
            className="no-service-section__info-icon"
          />
        </div>
      </div>
    </div>
  );
};

export default NoServiceSection;

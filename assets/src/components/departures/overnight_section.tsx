import type { ComponentType } from "react";

import Header from "./header";
import MoonIcon from "Images/moon.svg";
import { classWithModifier } from "Util/utils";
import FreeText, { FreeTextType } from "Components/free_text";

export type OvernightSection = {
  type: "overnight_section";
  header: Header;
  text: FreeTextType;
  with_headsign: boolean;
};

export const OvernightSection: ComponentType<OvernightSection> = ({
  header,
  text,
  with_headsign: withHeadsign,
}) => {
  return (
    <div className="departures-section overnight-section">
      <div
        className={classWithModifier(
          "departures-section-divider",
          !header.title && header.image_path ? "only-image-header" : "",
        )}
      ></div>
      <Header {...header} />
      <div className="departures__notice-row">
        <FreeText lines={text} />
        {withHeadsign ? (
          <div className="departures__overnight-no-service">Svc Ended</div>
        ) : (
          <MoonIcon className="departure-time__moon-icon" color="black" />
        )}
      </div>
    </div>
  );
};

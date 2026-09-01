import type { ComponentType } from "react";

import Header from "./header";
import { classWithModifier } from "Util/utils";
import FreeText, { FreeTextType } from "Components/free_text";

export type NoServiceSection = {
  type: "no_service_section";
  header: Header;
  text: FreeTextType;
  with_headsign: boolean;
};

export const NoServiceSection: ComponentType<NoServiceSection> = ({
  header,
  text,
  with_headsign: withHeadsign,
}) => {
  return (
    <div className="departures-section no-service-section">
      <div
        className={classWithModifier(
          "departures-section-divider",
          !header.title && header.image_path ? "only-image-header" : "",
        )}
      ></div>
      <Header {...header} />
      <div
        className={classWithModifier(
          "departures__notice-row",
          withHeadsign ? "with-headsign" : "",
        )}
      >
        <FreeText lines={text} />
        {withHeadsign && (
          <div className="departures__no-service">No svc today</div>
        )}
      </div>
    </div>
  );
};

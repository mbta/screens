import type { ComponentType } from "react";
import FreeText, { FreeTextType } from "Components/v2/free_text";
import { classWithModifier } from "Util/utils";

interface HeadwaySection {
  layout: string;
  text: FreeTextType;
}

const HeadwaySection: ComponentType<HeadwaySection> = ({ text, layout }) => {
  return (
    <div
      className={`departures-section ${classWithModifier(
        "headway-section",
        layout,
      )}`}
    >
      <FreeText lines={text} />
    </div>
  );
};

export default HeadwaySection;

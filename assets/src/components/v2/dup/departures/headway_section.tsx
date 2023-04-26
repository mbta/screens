import React from "react";
import FreeText from "Components/v2/free_text";
import { classWithModifier } from "Util/util";

const HeadwaySection = ({ text, layout }) => {
  return (
    <div
      className={`departures-section ${classWithModifier(
        "headway-section",
        layout
      )}`}
    >
      <FreeText lines={text} />
    </div>
  );
};

export default HeadwaySection;

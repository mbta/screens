import React from "react";

import DefaultNormalHeader from "Components/v2/normal_header";
import { getScreenSide } from "Util/utils";

const NormalHeader = ({ icon, text, time }) => {
  const classModifier = getScreenSide() === "solo" ? "solo" : "duo";

  return (
    <DefaultNormalHeader
      icon={icon}
      text={text}
      time={time}
      maxHeight={104}
      classModifier={classModifier}
      fullName
    />
  );
};

export default NormalHeader;

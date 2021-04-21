import React from "react";

import DefaultNormalHeader from "Components/v2/normal_header";
import { DUP_VERSION } from "Components/dup/version";

const NormalHeader = ({ icon, text, time }) => {
  return (
    <DefaultNormalHeader
      icon={icon}
      text={text}
      time={time}
      showUpdated={false}
      versionNumber={DUP_VERSION}
      maxHeight={208}
    />
  );
};

export default NormalHeader;

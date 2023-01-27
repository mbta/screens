import React from "react";

import DefaultNormalHeader from "Components/v2/normal_header";

const NormalHeader = ({ icon, text, time }) => {
  return (
    <DefaultNormalHeader
      icon={icon}
      text={text}
      time={time}
      maxHeight={104}
      fullName
    />
  );
};

export default NormalHeader;

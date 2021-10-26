import React from "react";

import DefaultNormalHeader from "Components/v2/normal_header";

const NormalHeader = ({ icon, text, time }) => {
  return (
    <DefaultNormalHeader
      icon={icon}
      text={text}
      time={time}
      showUpdated={true}
      maxHeight={208}
      showTo={true}
    />
  );
};

export default NormalHeader;

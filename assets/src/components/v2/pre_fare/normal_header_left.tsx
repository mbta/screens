import React from "react";

import DefaultNormalHeader from "Components/v2/normal_header";

const NormalHeaderLeft = ({ icon, text, time }) => {
  return (
    <DefaultNormalHeader
      icon={icon}
      text={text}
      time={time}
      showUpdated={false}
      maxHeight={208}
    />
  );
};

export default NormalHeaderLeft;

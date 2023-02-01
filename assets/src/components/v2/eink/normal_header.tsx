import React, { ComponentType } from "react";

import DefaultNormalHeader, { Icon } from "Components/v2/normal_header";

interface Props {
  icon: Icon;
  text: string;
  time: string;
  show_to: boolean;
}

const NormalHeader: ComponentType<Props> = ({ icon, text, time, show_to: showTo }) => {
  return (
    <DefaultNormalHeader
      icon={icon}
      text={text}
      time={time}
      showUpdated
      maxHeight={208}
      showTo={showTo}
    />
  );
};

export default NormalHeader;

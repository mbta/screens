import React from "react";

import DefaultNormalHeader, { Icon } from "Components/v2/normal_header";
import { DUP_VERSION } from "Components/dup/version";

interface NormalHeaderProps {
  text: string;
  time?: string;
  color?: string;
  accentPattern?: boolean;
}

const NormalHeader = ({text, time, color, accentPattern}: NormalHeaderProps) => {

  return (
    <DefaultNormalHeader
      icon={Icon.logo}
      text={text}
      time={time}
      version={DUP_VERSION}
      maxHeight={208}
      showTo={false}
      classModifiers={color}
      accentPattern={accentPattern}
    />
  );
};

export default NormalHeader;

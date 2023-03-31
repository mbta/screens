import React from "react";

import DefaultNormalHeader, { Icon } from "Components/v2/normal_header";
import { DUP_VERSION } from "Components/dup/version";

interface NormalHeaderProps {
  text: string;
  time?: string;
  color?: string;
  accentPattern?: string;
  code?: string;
}

const NormalHeader = ({
  text,
  time,
  color,
  accentPattern,
  code,
}: NormalHeaderProps) => {
  return (
    <DefaultNormalHeader
      icon={Icon.logo}
      text={text}
      time={time}
      // Currently, we don't use different codes that populating this would be useful...
      // But this was a feature available in v1, so just set it up here.
      version={DUP_VERSION + (code ? "; Maintenance code: " + code : "")}
      maxHeight={208}
      showTo={false}
      classModifiers={color}
      accentPattern={accentPattern}
    />
  );
};

export default NormalHeader;

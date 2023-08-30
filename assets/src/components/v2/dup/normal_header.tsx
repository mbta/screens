import React from "react";

import DefaultNormalHeader, { Icon } from "Components/v2/normal_header";
import { DUP_VERSION } from "Components/v2/dup/version";
import { usePlayerName } from "Hooks/outfront";

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
  const playerName = usePlayerName();
  let version = DUP_VERSION;
  if (playerName) {
    version = `${version}-${playerName}`;
  }
  if (code) {
    version = `${version}; Maintenance code: ${code}`;
  }

  return (
    <DefaultNormalHeader
      icon={color === "yellow" ? Icon.logo_negative : Icon.logo}
      text={text}
      time={time}
      // Currently, we don't use different codes that populating this would be useful...
      // But this was a feature available in v1, so just set it up here.
      version={version}
      maxHeight={208}
      showTo={false}
      classModifiers={color}
      accentPattern={accentPattern}
    />
  );
};

export default NormalHeader;

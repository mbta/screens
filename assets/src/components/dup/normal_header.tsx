import DefaultNormalHeader, { Icon } from "Components/normal_header";
import { DUP_VERSION } from "./version";
import { usePlayerName } from "Hooks/outfront";
import { getRotationIndex } from "Util/outfront";

interface NormalHeaderProps {
  text: string;
  time?: string;
  color?: string;
  accentPattern?: string;
}

const NormalHeader = ({
  text,
  time,
  color,
  accentPattern,
}: NormalHeaderProps) => {
  const playerName = usePlayerName();
  const rotationIndex = getRotationIndex();
  let version = DUP_VERSION;
  if (rotationIndex) {
    version = `${version}.${rotationIndex}`;
  }
  if (playerName) {
    version = `${version}-${playerName}`;
  }

  return (
    <DefaultNormalHeader
      icon={color === "yellow" ? Icon.logo_negative : Icon.logo}
      text={text}
      time={time}
      version={version}
      showTo={false}
      classModifier={color}
      accentPattern={accentPattern}
    />
  );
};

export default NormalHeader;

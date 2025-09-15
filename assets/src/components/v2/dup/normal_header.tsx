import DefaultNormalHeader, { Icon } from "Components/v2/normal_header";
import { DUP_VERSION } from "./version";
import { usePlayerName } from "Hooks/outfront";

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
  let version = DUP_VERSION;
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

import DefaultNormalHeader, { Icon } from "Components/normal_header";
import { usePlayerName } from "Hooks/outfront";
import { getRotationIndex, getVersion, isOutfront } from "Util/outfront";

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

  let version: string | undefined = undefined;

  if (isOutfront()) {
    version = [playerName, getVersion(), getRotationIndex()]
      .filter(Boolean)
      .join("/");
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

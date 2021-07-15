import React from "react";

import { imagePath, classWithModifiers } from "Util/util";

type Pill =
  | (TextPill & { type: "text" })
  | (IconPill & { type: "icon" })
  | (SlashedPill & { type: "slashed" });

interface BasePill {
  color: Color;
  outline?: boolean;
}

interface TextPill extends BasePill {
  text: string;
}

interface IconPill extends BasePill {
  icon: PillIcon;
}

interface SlashedPill extends BasePill {
  part1: string;
  part2: string;
}

type Color = "red" | "orange" | "green" | "blue" | "purple" | "yellow" | "teal";

type PillIcon = "rail" | "boat";

const TextRoutePill = ({ color, text, outline }: TextPill): JSX.Element => {
  const modifiers: string[] = [color];
  if (outline) {
    modifiers.push("outline");
  }

  return (
    <div className={classWithModifiers("route-pill", modifiers)}>
      <div className={classWithModifiers("route-pill__text", modifiers)}>
        {text}
      </div>
    </div>
  );
};

const pathForIcon = {
  rail: "/commuter-rail.svg",
  boat: "/ferry.svg",
};

const IconRoutePill = ({ icon, color, outline }: IconPill): JSX.Element => {
  const modifiers: string[] = [color];
  if (outline) {
    modifiers.push("outline");
  }

  const imgSrc = imagePath(pathForIcon[icon]);

  return (
    <div className={classWithModifiers("route-pill", modifiers)}>
      <div className="route-pill__icon">
        <img className="route-pill__icon-image" src={imgSrc} />
      </div>
    </div>
  );
};

const SlashedRoutePill = ({
  part1,
  part2,
  color,
  outline,
}: SlashedPill): JSX.Element => {
  const modifiers: string[] = [color];
  if (outline) {
    modifiers.push("outline");
  }

  return (
    <div className={classWithModifiers("route-pill", modifiers)}>
      <div className="route-pill__slashed-text">
        <div className="route-pill__slashed-part-1">{part1}/</div>
        <div className="route-pill__slashed-part-2">{part2}</div>
      </div>
    </div>
  );
};

const RoutePill = (pill: Pill): JSX.Element | null => {
  switch (pill.type) {
    case "text":
      return <TextRoutePill {...pill} />;
    case "icon":
      return <IconRoutePill {...pill} />;
    case "slashed":
      return <SlashedRoutePill {...pill} />;
    default:
      return null;
  }
};

const routePillKey = (pill: Pill): string => {
  switch (pill.type) {
    case "text":
      return pill.text;
    case "icon":
      return pill.icon;
    case "slashed":
      return `${pill.part1}-${pill.part2}`;
  }
};

export { Pill };
export { routePillKey };
export default RoutePill;

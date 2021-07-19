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

type PillIcon = "bus" | "light_rail" | "rail" | "boat";

const TextRoutePill = ({ color, text, outline }: TextPill): JSX.Element => {
  const modifiers: string[] = [color];
  if (outline) {
    modifiers.push("outline");
  }

  return (
    <div className={classWithModifiers("route-pill__text", modifiers)}>
      {text}
    </div>
  );
};

const pathForIcon = {
  bus: "/bus-black.svg",
  light_rail: "/light-rail.svg",
  rail: "/commuter-rail.svg",
  boat: "/ferry.svg",
};

const IconRoutePill = ({ icon }: IconPill): JSX.Element => {
  const imgSrc = imagePath(pathForIcon[icon]);

  return (
    <div className="route-pill__icon">
      <img className="route-pill__icon-image" src={imgSrc} />
    </div>
  );
};

const SlashedRoutePill = ({ part1, part2 }: SlashedPill): JSX.Element => {
  return (
    <div className="route-pill__slashed-text">
      <div className="route-pill__slashed-part-1">{part1}/</div>
      <div className="route-pill__slashed-part-2">{part2}</div>
    </div>
  );
};

const RoutePill = (pill: Pill): JSX.Element | null => {
  const modifiers: string[] = [pill.color];
  if (pill.outline) {
    modifiers.push("outline");
  }

  let innerContent = null;
  switch (pill.type) {
    case "text":
      innerContent = <TextRoutePill {...pill} />;
      break;
    case "icon":
      innerContent = <IconRoutePill {...pill} />;
      break;
    case "slashed":
      innerContent = <SlashedRoutePill {...pill} />;
  }

  return (
    <div className={classWithModifiers("route-pill", modifiers)}>
      {innerContent}
    </div>
  );
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

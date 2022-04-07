import React, { ComponentType } from "react";

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

const TextRoutePill: ComponentType<TextPill> = ({ color, text, outline }) => {
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

const IconRoutePill: ComponentType<IconPill> = ({ icon }) => {
  const imgSrc = imagePath(pathForIcon[icon]);

  return (
    <div className="route-pill__icon">
      <img className="route-pill__icon-image" src={imgSrc} />
    </div>
  );
};

const SlashedRoutePill: ComponentType<SlashedPill> = ({ part1, part2 }) => {
  return (
    <div className="route-pill__slashed-text">
      <div className="route-pill__slashed-part-1">{part1}/</div>
      <div className="route-pill__slashed-part-2">{part2}</div>
    </div>
  );
};

const RoutePill: ComponentType<Pill> = (pill) => {
  const modifiers: string[] = [pill.color];

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

  let branches = null;
  if (pill.branches) {
    branches = pill.branches.map((branch: string) => (
      <div key={branch} className={classWithModifiers("route-pill", modifiers.concat(["branch"]))}>
        <TextRoutePill {...pill} text={branch} />
      </div>
    ))
  }

  return (
    <>
      <div className={classWithModifiers("route-pill", modifiers)}>
        {innerContent}
        
      </div>
      {branches && 
        <div className="route-pills__branches">
          <span className="route-pills__branches__dot"></span>
          {branches}
        </div>
      }
    </>
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

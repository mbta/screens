import React from "react";

import { imagePath, classWithModifiers } from "Util/util";

const TextRoutePill = ({ color, text, outline }) => {
  let modifiers = [color];
  if (outline) {
    modifiers.push("outline");
  }

  return (
    <div className={classWithModifiers("route-pill", modifiers)}>
      <div className="route-pill__text">{text}</div>
    </div>
  );
};

const pathForIcon = {
  rail: "/commuter-rail.svg",
  boat: "/ferry.svg",
};

const IconRoutePill = ({ icon, color, outline }) => {
  let modifiers = [color];
  if (outline) {
    modifiers.push("outline");
  }

  const imgSrc = imagePath(pathForIcon[icon]);

  return (
    <div className={classWithModifiers("route-pill", modifiers)}>
      <div className="route-pill__icon">
        <img src={imgSrc} />
      </div>
    </div>
  );
};

const SlashedRoutePill = ({ part1, part2, color, outline }) => {
  let modifiers = [color];
  if (outline) {
    modifiers.push("outline");
  }

  return (
    <div className={classWithModifiers("route-pill", modifiers)}>
      <div className="route-pill__slashed-part-1">{part1}</div>/
      <div className="route-pill__slashed-part-2">{part2}</div>
    </div>
  );
};

const RoutePill = ({ type, ...data }) => {
  if (type === "text") {
    return <TextRoutePill {...data} />;
  } else if (type === "icon") {
    return <IconRoutePill {...data} />;
  } else if (type === "slashed") {
    return <SlashedRoutePill {...data} />;
  }

  return null;
};

export default RoutePill;

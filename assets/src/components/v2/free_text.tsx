import React from "react";
import _ from "lodash";

import { classWithModifier, classWithModifiers, imagePath } from "Util/util";

const pillIcons = ["red", "blue", "orange", "green", "silver"];

const iconPaths: { [key: string]: string } = _.mapValues(
  {
    warning: "alert.svg",
    x: "no-service-white.svg",
    shuttle: "bus-white.svg",
    subway: "subway-white.svg",
    "subway-negative-black": "subway-negative-black.svg",
    cr: "commuter-rail.svg",
    walk: "nearby-white.svg",
    green_b: "gl-b-color.svg",
    green_c: "gl-c-color.svg",
    green_d: "gl-d-color.svg",
    green_e: "gl-e-color.svg",
  },
  imagePath
);

const srcForIcon = (icon) => {
  return iconPaths[icon];
};

const getKey = (elt) => {
  if (typeof elt === "string") {
    return elt;
  } else if (elt.format !== undefined) {
    return `${elt.format}--${elt.text}`;
  } else if (elt.route !== undefined) {
    return `route-pill--${elt.route}`;
  } else if (elt.text !== undefined) {
    return `${elt.color}--${elt.text}`;
  } else if (elt.special !== undefined) {
    return `special--${elt.special}`;
  } else if (elt.icon !== undefined) {
    return `icon--${elt.icon}`;
  }
};

const Icon = ({ icon }) => {
  let iconElt;

  if (icon === null) {
    iconElt = null;
  } else if (pillIcons.includes(icon)) {
    iconElt = <RoutePill route={icon} />;
  } else {
    iconElt = <img className="free-text__icon-image" src={srcForIcon(icon)} />;
  }

  return <div className="free-text__icon-container">{iconElt}</div>;
};

const InlineIcon = ({ icon }) => {
  return (
    <span className="free-text__element free-text__inline-icon">
      <img className="free-text__inline-icon-image" src={srcForIcon(icon)} />
    </span>
  );
};

const FormatString = ({ format, text }) => {
  const modifiers = format === null ? [] : [format];
  const className = `free-text__element ${classWithModifiers(
    "free-text__string",
    modifiers
  )}`;

  return <span className={className}>{text}</span>;
};

const RoutePill = ({ route }) => {
  const routeName = {
    red: "RL",
    blue: "BL",
    orange: "OL",
    green: "GL",
    silver: "SL",
    cr: "CR",
    green_b: "GL·B",
    green_c: "GL·C",
    green_d: "GL·D",
    green_e: "GL·E",
  }[route];

  const branch = route.startsWith("green_") ? "branch" : "trunk";

  return (
    <span className="free-text__element free-text__route-container">
      <div className={classWithModifier("free-text__route-pill", route)}>
        <div
          className={classWithModifier("free-text__route-pill__text", branch)}
        >
          {routeName}
        </div>
      </div>
    </span>
  );
};

const TextPill = ({ color, text }) => {
  return (
    <span className="free-text__element free-text__pill-container">
      <div className={classWithModifier("free-text__text-pill", color)}>
        <div className="free-text__text-pill__text">{text}</div>
      </div>
    </span>
  );
};

const Special = ({ data }) => {
  if (data === "break") {
    return <br />;
  }

  return null;
};

const FreeTextElement = ({ elt }) => {
  if (typeof elt === "string") {
    return <FormatString text={elt} format={null} />;
  } else if (elt.format !== undefined) {
    return <FormatString text={elt.text} format={elt.format} />;
  } else if (elt.route !== undefined) {
    return <RoutePill route={elt.route} />;
  } else if (elt.color !== undefined) {
    return <TextPill color={elt.color} text={elt.text} />;
  } else if (elt.special !== undefined) {
    return <Special data={elt.special} />;
  } else if (elt.icon !== undefined) {
    return <InlineIcon icon={elt.icon} />;
  }

  return null;
};

const FreeText = ({ elements }) => {
  return (
    <div className="free-text">
      {elements.map((elt) => (
        <FreeTextElement elt={elt} key={getKey(elt)} />
      ))}
    </div>
  );
};

export default FreeText;
export { srcForIcon };

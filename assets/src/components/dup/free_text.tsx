import React from "react";

import { classWithModifier, classWithModifiers } from "Util/util";

const srcForIcon = (icon) => {
  return {
    warning: "/images/alert.svg",
    x: "/images/no-service-white.svg",
    shuttle: "/images/bus-white.svg",
    subway: "/images/subway-white.svg",
    cr: "/images/commuter-rail.svg",
    walk: "/images/nearby-white.svg",
  }[icon];
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
  }
};

const Icon = ({ icon }) => {
  let iconElt;

  if (["red", "blue", "orange", "green", "silver"].includes(icon)) {
    iconElt = <RoutePill route={icon} />;
  } else {
    iconElt = <img className="free-text__icon-image" src={srcForIcon(icon)} />;
  }

  return <div className="free-text__icon-container">{iconElt}</div>;
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
  }[route];

  return (
    <span className="free-text__element free-text__route-container">
      <div className={classWithModifier("free-text__route-pill", route)}>
        {routeName}
      </div>
    </span>
  );
};

const TextPill = ({ color, text }) => {
  return (
    <span className="free-text__element free-text__pill-container">
      <div className={classWithModifier("free-text__text-pill", color)}>
        {text}
      </div>
    </span>
  );
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
  }

  return null;
};

const FreeTextLine = ({ icon, text }) => {
  return (
    <div className="free-text__line-container">
      <Icon icon={icon} />
      <div className="free-text__line">
        {text.map((elt) => (
          <FreeTextElement elt={elt} key={getKey(elt)} />
        ))}
      </div>
    </div>
  );
};

const FreeText = ({ lines }) => {
  if (Array.isArray(lines)) {
    const [{ icon: icon1, text: text1 }, { icon: icon2, text: text2 }] = lines;
    return (
      <div className="free-text">
        <FreeTextLine icon={icon1} text={text1} />
        <FreeTextLine icon={icon2} text={text2} />
      </div>
    );
  } else {
    const { icon, text } = lines;
    return (
      <div className="free-text">
        <FreeTextLine icon={icon} text={text} />
      </div>
    );
  }
};

export default FreeText;
export { getKey, FreeTextLine, FreeTextElement };

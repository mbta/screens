import moment from "moment";
import "moment-timezone";

export const classWithModifier = (baseClass, modifier) => {
  return `${baseClass} ${baseClass}--${modifier}`;
};

export const classWithModifiers = (baseClass, modifiers) => {
  if (modifiers.length === 0) {
    return baseClass;
  } else {
    return (
      `${baseClass} ` + modifiers.map((m) => `${baseClass}--${m}`).join(" ")
    );
  }
};

export const formatTimeString = (timeString) =>
  moment(timeString).tz("America/New_York").format("h:mm");

export const isDup = () => location.href.startsWith("file:");

export const imagePath = (fileName: string): string =>
  isDup() ? `images/${fileName}` : `/images/${fileName}`;

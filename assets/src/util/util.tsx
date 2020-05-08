import moment from "moment";
import "moment-timezone";

export const classWithModifier = (baseClass, modifier) => {
  return `${baseClass} ${baseClass}--${modifier}`;
};

export const formatTimeString = (timeString) =>
  moment(timeString).tz("America/New_York").format("h:mm");

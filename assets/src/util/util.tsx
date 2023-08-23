import moment from "moment";
import "moment-timezone";
import { getDatasetValue } from "Util/dataset";
import { isOFM } from "Util/outfront";

export const classWithModifier = (baseClass, modifier) => {
  if (!modifier) {
    return baseClass;
  } else {
    return `${baseClass} ${baseClass}--${modifier}`;
  }
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

export const formatTimeString = (timeString: string) =>
  moment(timeString).tz("America/New_York").format("h:mm");

export const imagePath = (fileName: string): string =>
  isOFM() ? `images/${fileName}` : `/images/${fileName}`;

export const pillPath = (fileName: string): string =>
  isOFM() ? `images/pills/${fileName}` : `/images/pills/${fileName}`;

export const isRealScreen = () =>
  isOFM() || getDatasetValue("isRealScreen") === "true";

type ScreenSide = "left" | "right";
const isScreenSide = (value: any): value is ScreenSide => {
  return value === "left" || value === "right";
};

/**
 * For screen types that are split across two separate displays (pre-fare),
 * this gets the value of the data attribute dictating which side to show.
 *
 * Returns null if the data attribute is missing or not a valid screen side value.
 */
export const getScreenSide = (): ScreenSide | null => {
  const screenSide = getDatasetValue("screenSide");
  return isScreenSide(screenSide) ? screenSide : null;
};

export const firstWord = (str: string): string => str.split(" ")[0];

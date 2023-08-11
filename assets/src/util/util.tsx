import { ROTATION_INDEX } from "Components/v2/dup/rotation_index";
import { TRIPTYCH_PANE } from "Components/v2/triptych/pane";
import moment from "moment";
import "moment-timezone";
import { getDatasetValue } from "Util/dataset";

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

/**
 * Returns true if this client is running on an Outfront Media screen.
 * (A DUP or a triptych.)
 *
 * Use this for OFM-specific logic that is common to both the DUP and triptych apps.
 */
export const isOFM = () => location.href.startsWith("file:");

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

type RotationIndex = "0" | "1" | "2";
const isRotationIndex = (value: any): value is RotationIndex => {
  return value === "0" || value === "1" || value === "2";
};

type TriptychPane = "left" | "middle" | "right";
const isTriptychPane = (value: any): value is TriptychPane => {
  return value === "left" || value === "middle" || value === "right";
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

export const getRotationIndex = (): RotationIndex | null => {
  const rotationIndex = isOFM()
    ? ROTATION_INDEX.toString()
    : getDatasetValue("rotationIndex");

  return isRotationIndex(rotationIndex) ? rotationIndex : null;
};

export const getTriptychPane = (): TriptychPane | null => {
  const pane = isOFM()
    ? TRIPTYCH_PANE
    : getDatasetValue("triptychPane");

  return isTriptychPane(pane) ? pane : null;
}

export const firstWord = (str: string): string => str.split(" ")[0];

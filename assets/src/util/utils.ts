import moment from "moment";
import "moment-timezone";
import { RefObject } from "react";
import cx from "classnames";

import { getDatasetValue } from "Util/dataset";
import { isDup } from "Util/outfront";

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
    return cx(
      baseClass,
      ...modifiers.filter((m) => m).map((m) => `${baseClass}--${m}`),
    );
  }
};

export const formatTimeString = (timeString: string) =>
  moment(timeString).tz("America/New_York").format("h:mm");

export const hasOverflowY = (ref: RefObject<Element>): boolean =>
  !!ref.current && ref.current.scrollHeight > ref.current.clientHeight;

export const hasOverflowX = (ref: RefObject<Element>): boolean =>
  !!ref.current && ref.current.scrollWidth > ref.current.clientWidth;

export const imagePath = (fileName: string): string =>
  isDup() ? `images/${fileName}` : `/images/${fileName}`;

export const isRealScreen = () =>
  isDup() || getDatasetValue("isRealScreen") === "true";

type ScreenSide = "left" | "right" | "duo" | "solo";
const isScreenSide = (value: any): value is ScreenSide => {
  return (
    value === "left" || value === "right" || value === "duo" || value === "solo"
  );
};

/**
 * For screen types that can be split across multiple display units, indicates
 * which display was requested for this instance of the app. Returns `null` if
 * this data is missing or invalid.
 *
 * - `left`: show only the left side of a duo screen.
 * - `right`: show only the right side of a duo screen.
 * - `duo`: show both sides of a duo screen.
 * - `solo`: show "the only side" of a solo screen.
 */
export const getScreenSide = (): ScreenSide | null => {
  const screenSide = getDatasetValue("screenSide");
  return isScreenSide(screenSide) ? screenSide : null;
};

export const firstWord = (str: string): string => str.split(" ")[0];

export const formatCause = (cause: string) =>
  (cause.charAt(0).toUpperCase() + cause.substring(1)).replace("_", " ");

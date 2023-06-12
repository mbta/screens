///////////////////////
// SERVER DATA TYPES //
///////////////////////

import useTextResizer from "Hooks/v2/use_text_resizer";
import { firstWord } from "Util/util";

export interface SubwayStatusData {
  blue: Section;
  orange: Section;
  red: Section;
  green: Section;
}

export type Section = ContractedSection | ExtendedSection;

export interface ContractedSection {
  type: "contracted";
  alerts: [Alert] | [Alert, Alert];
}

export interface ExtendedSection {
  type: "extended";
  alert: Alert;
}

export interface Alert {
  route_pill?: SubwayStatusPill;
  status: string;
  location: AlertLocation;
  station_count?: number;
}

export interface SubwayStatusPill {
  color: LineColor;
  branches?: GLBranch[];
}

export interface GLMultiPill extends SubwayStatusPill {
  // Specifically, a non-empty array
  branches: GLBranch[];
}

export type AlertLocation = string | AlertLocationMap | null;

export interface AlertLocationMap {
  full: string;
  abbrev: string;
}

export enum LineColor {
  Blue = "blue",
  Orange = "orange",
  Red = "red",
  Green = "green",
}

export enum GLBranch {
  B = "b",
  C = "c",
  D = "d",
  E = "e",
}

/////////////////
// TYPE GUARDS //
/////////////////

export const isGLMultiPill = (pill?: SubwayStatusPill): pill is GLMultiPill =>
  (pill?.branches?.length ?? 0) > 0;

export const isAlertLocationMap = (
  location: AlertLocation
): location is AlertLocationMap =>
  location !== null && typeof location === "object";

export const isContracted = (section: Section): section is ContractedSection =>
  section.type === "contracted";

export const isExtended = (section: Section): section is ExtendedSection =>
  section.type === "extended";

/////////////
// HELPERS //
/////////////

/**
 * When appearing in a contracted status, we always make these changes to alert content:
 * - Replace " minute(s)" with "m" in `alert.status`, if it's a delay
 * - Clear the `location` entirely, if the alert's pill uses all 4 GL branches
 */
export const adjustAlertForContractedStatus = (alert: Alert): Alert => ({
  ...alert,
  status: delayMinutesToM(alert.status),
  location: clearLocationForAllGLBranchesAlert(
    alert.location,
    alert.route_pill
  ),
});

const delayMinutesToM = (status: string): string =>
  status.startsWith("Delays")
    ? status.replace(/(?<N>\d+) minutes?$/i, "$<N>m")
    : status;

const clearLocationForAllGLBranchesAlert = (
  location: AlertLocation,
  routePill?: SubwayStatusPill
): AlertLocation => {
  if (isGLMultiPill(routePill) && new Set(routePill.branches).size === 4) {
    return null;
  }
  return location;
};

/**
 * Uniquely identifies an alert line so that if anything changes, the text-
 * resizing logic resets.
 */
export const getAlertID = (
  alert: Alert,
  statusType: Section["type"],
  index: number
): string => {
  const location = isAlertLocationMap(alert.location)
    ? `${alert.location.abbrev}-${alert.location.full}`
    : alert.location;

  const routePill = `${alert?.route_pill?.color ?? ""}-${
    alert?.route_pill?.branches?.join("") ?? ""
  }`;

  return `${statusType}-${index}-${location}-${routePill}`;
};

export const isContractedWith1Alert = (
  section: Section
): section is ContractedSection =>
  isContracted(section) && section.alerts.length === 1;

// Ordered from "smallest" to "largest"
enum FittingStep {
  PerAlertEffect,
  Abbrev,
  FullSize,
}

export const useSubwayStatusTextResizer = (rowHeight: number, id: string, status: string) => {
  const { ref, size: fittingStep, isDone } = useTextResizer({
    sizes: [
      FittingStep.PerAlertEffect,
      FittingStep.Abbrev,
      FittingStep.FullSize,
    ],
    maxHeight: rowHeight,
    resetDependencies: [id],
  });

  let [abbrev, truncateStatus, replaceLocationWithUrl] = [false, false, false];
  switch (fittingStep) {
    case FittingStep.FullSize:
      break;
    case FittingStep.Abbrev:
      abbrev = true;
      break;
    case FittingStep.PerAlertEffect:
      abbrev = true;
      switch (firstWord(status)) {
        case "Delays":
          truncateStatus = true;
          break;
        case "Bypassing":
          truncateStatus = true;
          replaceLocationWithUrl = true;
          break;
        case "Suspension":
          replaceLocationWithUrl = true;
          break;
        case "Shuttle":
        default:
          break;
      }
  }

  return { ref, abbrev, truncateStatus, replaceLocationWithUrl, fittingStep, isDone };
};

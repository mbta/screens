import useAutoSize from "Hooks/use_auto_size";
import { firstWord } from "Util/utils";

///////////////////////
// SERVER DATA TYPES //
///////////////////////

export interface SubwayStatusData {
  blue: Section;
  orange: Section;
  red: Section;
  green: Section;
}

export type Section = ContractedSection | ExtendedSection;

interface ContractedSection {
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

type AlertLocation = string | AlertLocationMap | null;

interface AlertLocationMap {
  full: string;
  abbrev: string;
}

export interface SubwayStatusPill {
  color: LineColor;
  branches?: Branch[];
  text?: string;
}

export interface MultiPill extends SubwayStatusPill {
  // Specifically, a non-empty array
  branches: Branch[];
}

export enum LineColor {
  Blue = "blue",
  Orange = "orange",
  Red = "red",
  Green = "green",
}

enum Branch {
  // Green Line branches
  B = "b",
  C = "c",
  D = "d",
  E = "e",
  // Red Line branch (Mattapan)
  M = "m",
}

/////////////////
// TYPE GUARDS //
/////////////////

export const isMultiPill = (pill?: SubwayStatusPill): pill is MultiPill =>
  (pill?.branches?.length ?? 0) > 0;

const isAlertLocationMap = (
  location: AlertLocation,
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
    alert.route_pill,
  ),
});

const delayMinutesToM = (status: string): string =>
  status.startsWith("Delays")
    ? status.replace(/(?<N>\d+) minutes?$/i, "$<N>m")
    : status;

const clearLocationForAllGLBranchesAlert = (
  location: AlertLocation,
  routePill?: SubwayStatusPill,
): AlertLocation => {
  // Only clear location if it's a Green Line pill with all 4 GL branches
  if (
    isMultiPill(routePill) &&
    routePill.color === LineColor.Green &&
    new Set(routePill.branches).size === 4
  ) {
    return null;
  }
  return location;
};

/**
 * Uniquely identifies an alert line so that if anything changes, the text-
 * resizing logic resets.
 */
const getAlertID = (
  alert: Alert,
  statusType: Section["type"],
  index: number = 0,
): string => {
  const location = isAlertLocationMap(alert.location)
    ? `${alert.location.abbrev}-${alert.location.full}`
    : alert.location;

  const routePill = `${alert?.route_pill?.color ?? ""}-${alert?.route_pill?.branches?.join("") ?? ""}`;

  return `${statusType}-${index}-${location}-${routePill}`;
};

export const isContractedWith1Alert = (
  section: Section,
): section is ContractedSection =>
  isContracted(section) && section.alerts.length === 1;

// Ordered from "largest" to "smallest"
enum FittingStep {
  FullSize = "FullSize",
  Abbrev = "Abbrev",
  PerAlertEffect = "PerAlertEffect",
}

export const useSubwayStatusTextResizer = (
  alert: Alert,
  type: "contracted" | "extended",
) => {
  const id = getAlertID(alert, type);
  const steps =
    type === "contracted"
      ? [FittingStep.FullSize, FittingStep.Abbrev, FittingStep.PerAlertEffect]
      : [FittingStep.FullSize, FittingStep.Abbrev];
  const { ref, step: fittingStep } = useAutoSize(steps, id);

  const isStopsSkipped = /Stops? Skipped/.test(alert.status);
  const isSuspension = firstWord(alert.status) === "Suspension";
  const isDelays = firstWord(alert.status) === "Delays";

  const location = (() => {
    if (
      fittingStep === FittingStep.PerAlertEffect &&
      (isStopsSkipped || isSuspension)
    ) {
      return "mbta.com/alerts";
    } else if (isAlertLocationMap(alert.location)) {
      return fittingStep === FittingStep.Abbrev ||
        fittingStep === FittingStep.PerAlertEffect
        ? alert.location.abbrev
        : alert.location.full;
    } else {
      return alert.location;
    }
  })();

  const status =
    fittingStep === FittingStep.PerAlertEffect && isDelays
      ? "Delays"
      : alert.status;
  const isLastStep = fittingStep === steps.at(-1);

  return { ref, location, status, isLastStep };
};

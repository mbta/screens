import React, { ComponentType, forwardRef } from "react";
import { classWithModifier, classWithModifiers, imagePath } from "Util/util";
import useTextResizer from "Hooks/v2/use_text_resizer";

///////////////////////
// SERVER DATA TYPES //
///////////////////////

interface SubwayStatusData {
  blue: Section;
  orange: Section;
  red: Section;
  green: Section;
}

type Section = ContractedSection | ExtendedSection;

interface ContractedSection {
  type: "contracted";
  alerts: [Alert] | [Alert, Alert];
}

interface ExtendedSection {
  type: "extended";
  alert: Alert;
}

interface Alert {
  route_pill?: SubwayStatusPill;
  status: string;
  location: AlertLocation;
}

interface SubwayStatusPill {
  color: LineColor;
  branches?: GLBranch[];
}

interface GLMultiPill extends SubwayStatusPill {
  // Specifically, a non-empty array
  branches: GLBranch[];
}

type AlertLocation = string | AlertLocationMap | null;

interface AlertLocationMap {
  full: string;
  abbrev: string;
}

enum LineColor {
  Blue = "blue",
  Orange = "orange",
  Red = "red",
  Green = "green",
}

enum GLBranch {
  B = "b",
  C = "c",
  D = "d",
  E = "e",
}

/////////////////
// TYPE GUARDS //
/////////////////

const isGLMultiPill = (pill?: SubwayStatusPill): pill is GLMultiPill =>
  (pill?.branches?.length ?? 0) > 0;

const isAlertLocationMap = (
  location: AlertLocation
): location is AlertLocationMap =>
  location !== null && typeof location === "object";

const isContracted = (section: Section): section is ContractedSection =>
  section.type === "contracted";

const isExtended = (section: Section): section is ExtendedSection =>
  section.type === "extended";

////////////////
// COMPONENTS //
////////////////

const SubwayStatus: ComponentType<SubwayStatusData> = (props) => {
  const { blue, orange, red, green } = props;

  return (
    <div className="subway-status">
      {/* <span className="subway-status__header">Current Subway Service</span> */}
      <LineStatus section={blue} color={LineColor.Blue} />
      <LineStatus section={orange} color={LineColor.Orange} />
      <LineStatus section={red} color={LineColor.Red} />
      <LineStatus section={green} color={LineColor.Green} />
    </div>
  );
};

type LineStatusProps = { section: Section; color: LineColor };

const LineStatus: ComponentType<LineStatusProps> = ({ section, color }) => {
  let row;
  switch (section.type) {
    case "contracted":
      row = <ContractedStatus alerts={section.alerts} />;
      break;
    case "extended":
      row = <ExtendedStatus alert={section.alert} />;
  }

  return (
    <div className="subway-status_row">
      <div className="subway-status_route-pill-container">
        <SubwayStatusRoutePill routePill={{ color: color }} />
      </div>
      {row}
      <div className="subway-status_status_rule" />
    </div>
  );
};

type ContractedStatusProps = Pick<ContractedSection, "alerts">;

const ContractedStatus: ComponentType<ContractedStatusProps> = ({ alerts }) => {
  return (
    <div className="subway-status_status">
      {alerts.map((alert, index) => {
        const adjustedAlert = adjustAlertForContractedStatus(alert);
        const id = getAlertID(adjustedAlert, "contracted", index);
        return <ContractedAlert {...adjustedAlert} id={id} key={id} />;
      })}
    </div>
  );
};

type ExtendedStatusProps = Pick<ExtendedSection, "alert">;

const ExtendedStatus: ComponentType<ExtendedStatusProps> = ({ alert }) => {
  return (
    <div className={classWithModifier("subway-status_status", "extended")}>
      <ExtendedAlert {...alert} />
      <div className="subway-status_status_rule" />
    </div>
  );
};

interface AlertWithID extends Alert {
  // needed to ensure stateful components (e.g. SizedAlertLine) reset when appropriate
  id: string;
}

// Ordered from "smallest" to "largest"
enum FittingStep {
  PerAlertEffect,
  Abbrev,
  FullSize,
}

/**
 * Pixel height of a ContractedAlert. This should match the height of the route pill, since
 * it's the tallest element in the row.
 */
const CONTRACTED_ROW_HEIGHT = 64;

const ALERTS_URL = "mbta.com/alerts";

const ContractedAlert: ComponentType<AlertWithID> = ({
  route_pill: routePill,
  status,
  location,
  id,
}) => {
  const { ref, size: fittingStep } = useTextResizer({
    sizes: [
      FittingStep.PerAlertEffect,
      FittingStep.Abbrev,
      FittingStep.FullSize,
    ],
    maxHeight: CONTRACTED_ROW_HEIGHT,
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
        case "Suspension":
        case "Bypassing":
          // For "Bypassing", we also replace station names with a count in the status,
          // but that decision happens on the server since it only depends on
          // the number of stations bypassed--no pixel measurement necessary.
          replaceLocationWithUrl = true;
          break;
        case "Shuttle":
        default:
          break;
      }
  }

  let locationText: string | null;
  if (replaceLocationWithUrl) {
    locationText = ALERTS_URL;
  } else if (isAlertLocationMap(location)) {
    locationText = abbrev ? location.abbrev : location.full;
  } else {
    locationText = location;
  }

  // If we're on the last attempt to fit text in the row and it still overflows,
  // we prevent it from wrapping or pushing other content out of place.
  const hideOverflow = fittingStep === FittingStep.PerAlertEffect;

  return (
    <BasicAlert
      routePill={routePill}
      status={truncateStatus ? firstWord(status) : status}
      location={locationText}
      hideOverflow={hideOverflow}
      ref={ref}
    />
  );
};

const ExtendedAlert: ComponentType<Alert> = ({
  route_pill: routePill,
  status,
  location,
}) => {
  let locationText: string | null;
  if (isAlertLocationMap(location)) {
    locationText = location.full;
  } else {
    locationText = location;
  }

  return (
    <BasicAlert
      routePill={routePill}
      status={status}
      location={locationText}
      hideOverflow
    />
  );
};

const NORMAL_STATUS = "Normal Service";

interface BasicAlertProps extends Omit<Alert, "route_pill"> {
  routePill?: Alert["route_pill"];
  location: string | null;
  hideOverflow?: boolean;
}

const BasicAlert = forwardRef<HTMLDivElement, BasicAlertProps>(
  ({ routePill, status, location, hideOverflow = false }, ref) => {
    let textContainerClassName = "subway-status_alert_text-container";

    if (status === NORMAL_STATUS) {
      textContainerClassName = classWithModifier(
        textContainerClassName,
        "normal-service"
      );
    }

    return (
      <div className="subway-status_alert">
        {routePill?.branches && (
          <div className="subway-status_alert_route-pill-container">
            <SubwayStatusRoutePill routePill={routePill} />
          </div>
        )}
        <div className={textContainerClassName} ref={ref}>
          {status && <span>{status}</span>}
          {location && (
            <span className="subway-status_alert_location-text">
              {location}
            </span>
          )}
        </div>
      </div>
    );
  }
);

const SubwayStatusRoutePill: ComponentType<{ routePill: SubwayStatusPill }> = ({
  routePill,
}) => {
  if (isGLMultiPill(routePill)) {
    const sortedUniqueBranches = Array.from(new Set(routePill.branches)).sort();
    return <GLBranchPillGroup branches={sortedUniqueBranches} />;
  } else {
    return (
      <img
        src={getStandardLinePillPath(routePill.color)}
        className="pill-icon"
      />
    );
  }
};

const GLBranchPillGroup: ComponentType<Pick<GLMultiPill, "branches">> = ({
  branches: [firstBranch, ...rest],
}) => {
  return (
    <>
      <img src={getGLComboPillPath(firstBranch)} className="pill-icon" />
      {rest.map((branch) => (
        <img
          src={getGLBranchLetterPillPath(branch)}
          className="branch-icon"
          key={branch}
        />
      ))}
    </>
  );
};

/////////////
// HELPERS //
/////////////

/**
 * Uniquely identifies an alert line so that if anything changes, the text-
 * resizing logic resets.
 */
const getAlertID = (
  alert: Alert,
  statusType: "contracted" | "extended",
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

/**
 * When appearing in a contracted status, we always make these changes to alert content:
 * - Replace " minute(s)" with "m" in `alert.status`, if it's a delay
 * - Clear the `location` entirely, if the alert's pill uses all 4 GL branches
 */
const adjustAlertForContractedStatus = (alert: Alert): Alert => ({
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

const firstWord = (str: string): string => str.split(" ")[0];

const getStandardLinePillPath = (lineColor: LineColor) =>
  pillPath(`${lineColor}-line.svg`);

const isContractedWith1Alert = (section: Section) =>
  isContracted(section) && section.alerts.length === 1;

const getGLComboPillPath = (branch: GLBranch) => pillPath(`gl-${branch}.svg`);

const getGLBranchLetterPillPath = (branch: GLBranch) =>
  pillPath(`green-${branch}-circle.svg`);

const pillPath = (pillFilename: string) =>
  imagePath(`pills/eink/${pillFilename}`);

export default SubwayStatus;

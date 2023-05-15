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
  const { blue, orange, red, green } = cleanUpServerData(props);

  return (
    <div className="subway-status">
      <LineStatus section={blue} showRule />
      <LineStatus section={orange} showRule />
      <LineStatus section={red} showRule />
      <LineStatus section={green} showRule={shouldShowLastRule(props)} />
    </div>
  );
};

interface WithRule {
  showRule: boolean;
}

type LineStatusProps = { section: Section } & WithRule;

const LineStatus: ComponentType<LineStatusProps> = ({ section, showRule }) => {
  switch (section.type) {
    case "contracted":
      return <ContractedStatus alerts={section.alerts} showRule={showRule} />;
    case "extended":
      return <ExtendedStatus alert={section.alert} showRule={showRule} />;
  }
};

type ContractedStatusProps = Pick<ContractedSection, "alerts"> & WithRule;

const ContractedStatus: ComponentType<ContractedStatusProps> = ({
  alerts,
  showRule,
}) => {
  const modifiers = ["contracted"];
  if (alerts.length == 1) {
    modifiers.push("one-alert");
  } else {
    modifiers.push("two-alerts");
  }

  if (alerts?.[1]?.route_pill) {
    modifiers.push("has-second-pill");
  }

  return (
    <div className={classWithModifiers("subway-status_status", modifiers)}>
      {alerts.map((alert, index) => {
        const adjustedAlert = adjustAlertForContractedStatus(alert);
        const id = getAlertID(adjustedAlert, "contracted", index);
        return <ContractedAlert {...adjustedAlert} id={id} key={id} />;
      })}
      {showRule && <div className="subway-status_status_rule" />}
    </div>
  );
};

type ExtendedStatusProps = Pick<ExtendedSection, "alert"> & WithRule;

const ExtendedStatus: ComponentType<ExtendedStatusProps> = ({
  alert,
  showRule,
}) => {
  return (
    <div className={classWithModifier("subway-status_status", "extended")}>
      <ExtendedAlert {...alert} />
      {showRule && <div className="subway-status_status_rule" />}
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
 * Max pixel height of a ContractedAlert's outermost div element when content doesn't wrap.
 *
 * When the text wraps to a second line it's more than that, which is all we care about to detect overflows.
 */
const CONTRACTED_ALERT_MAX_HEIGHT = 80;

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
    maxHeight: CONTRACTED_ALERT_MAX_HEIGHT,
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
    let containerClassName = "subway-status_alert";
    containerClassName = classWithModifier(
      containerClassName,
      routePill ? "has-pill" : "no-pill"
    );

    let textContainerClassName = "subway-status_alert_text-container";
    if (hideOverflow) {
      textContainerClassName = classWithModifier(
        textContainerClassName,
        "hide-overflow"
      );
    }

    let statusTextClassName = "subway-status_alert_status-text";
    if (status === NORMAL_STATUS) {
      statusTextClassName = classWithModifier(
        statusTextClassName,
        "normal-service"
      );
    }

    return (
      <div className={containerClassName} >
        <div className="subway-status_alert-sizer" ref={ref}>
          <div className="subway-status_alert_route-pill-container">
            {routePill && <SubwayStatusRoutePill routePill={routePill} />}
          </div>
          <div className={textContainerClassName}>
            {status && <span className={statusTextClassName}>{status}</span>}
            {location && (
              <span className="subway-status_alert_location-text">
                {location}
              </span>
            )}
          </div>
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
 * Tweaks the widget data received from the server to avoid awkward presentation in exceptional cases:
 * - Converts extended statuses with no location text to single-row contracted statuses
 */
const cleanUpServerData = (data: SubwayStatusData): SubwayStatusData => ({
  blue: convertLocationlessExtendedAlertToContracted(data.blue),
  orange: convertLocationlessExtendedAlertToContracted(data.orange),
  red: convertLocationlessExtendedAlertToContracted(data.red),
  green: convertLocationlessExtendedAlertToContracted(data.green),
});

const convertLocationlessExtendedAlertToContracted = (
  section: Section
): Section =>
  isExtendedWithNoLocation(section)
    ? { type: "contracted", alerts: [section.alert] }
    : section;

/**
 * Uniquely identifies an alert line so that if anything changes, the text-
 * resizing logic resets.
 */
const getAlertID = (
  alert: Alert,
  statusType: Section["type"],
  index: number
): string => {
  const location = isAlertLocationMap(alert.location)
    ? `${alert.location.abbrev}-${alert.location.full}`
    : alert.location;

  const routePill = `${alert?.route_pill?.color ?? ""}-${alert?.route_pill?.branches?.join("") ?? ""
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

/**
 * Determines whether we should show the last rule, below the Green Line section.
 *
 * We show the last rule as long as the last pill in the pill column is no lower
 * than where it would be if all statuses were normal.
 *
 * This is the case when the two following conditions are met:
 * - The first 3 sections (BL, OL, RL) are contracted with 1 alert (or normal status)
 * - The GL section is *either*:
 *   - extended, *or*
 *   - contracted without a separate pill on its second alert (or just no second alert)
 *
 * In all other cases, we do not show the last rule.
 */
const shouldShowLastRule = ({ blue, orange, red, green }: SubwayStatusData) => {
  const firstThree = [blue, orange, red];

  const firstThreeContracted = firstThree.every(isContractedWith1Alert);
  const glExtended = isExtended(green);
  const glContractedWithNoSecondPill =
    isContracted(green) && !green.alerts?.[1]?.route_pill;

  return firstThreeContracted && (glExtended || glContractedWithNoSecondPill);
};

const getStandardLinePillPath = (lineColor: LineColor) =>
  pillPath(`${lineColor}-line.svg`);

const isContractedWith1Alert = (
  section: Section
): section is ContractedSection =>
  isContracted(section) && section.alerts.length === 1;

const isExtendedWithNoLocation = (
  section: Section
): section is ExtendedSection => isExtended(section) && !section.alert.location;

const getGLComboPillPath = (branch: GLBranch) => pillPath(`gl-${branch}.svg`);

const getGLBranchLetterPillPath = (branch: GLBranch) =>
  pillPath(`green-${branch}-circle.svg`);

const pillPath = (pillFilename: string) => imagePath(`pills/${pillFilename}`);

export default SubwayStatus;

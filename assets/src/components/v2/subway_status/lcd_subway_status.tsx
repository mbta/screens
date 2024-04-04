import React, { ComponentType, forwardRef } from "react";
import {
  classWithModifier,
  classWithModifiers,
  firstWord,
} from "Util/util";
import { STRING_TO_SVG, getHexColor } from "Util/svg_utils";
import {
  Alert,
  ContractedSection,
  ExtendedSection,
  GLMultiPill,
  Section,
  SubwayStatusData,
  SubwayStatusPill,
  adjustAlertForContractedStatus,
  getAlertID,
  isAlertLocationMap,
  isContracted,
  isContractedWith1Alert,
  isExtended,
  isGLMultiPill,
  useSubwayStatusTextResizer,
  FittingStep,
} from "./subway_status_common";

////////////////
// COMPONENTS //
////////////////

const LcdSubwayStatus: ComponentType<SubwayStatusData> = (props) => {
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
      <ExtendedAlert {...alert} id={getAlertID(alert, "extended")} />
      {showRule && <div className="subway-status_status_rule" />}
    </div>
  );
};

interface AlertWithID extends Alert {
  // needed to ensure stateful components (e.g. ContractedAlert) reset when appropriate
  id: string;
}

/**
 * Max pixel height of each alert type's "subway-status_alert-sizer" div element when content doesn't wrap.
 *
 * When the text wraps to a second line it's more than that, which is all we care about to detect overflows.
 */
const CONTRACTED_ALERT_MAX_HEIGHT = 82;
const EXTENDED_ALERT_MAX_HEIGHT = 120;

const CONTRACTED_ALERT_FITTING_STEPS = [
  FittingStep.PerAlertEffect,
  FittingStep.Abbrev,
  FittingStep.FullSize,
];
const EXTENDED_ALERT_FITTING_STEPS = [FittingStep.Abbrev, FittingStep.FullSize];

const ALERTS_URL = "mbta.com/alerts";

const ContractedAlert: ComponentType<AlertWithID> = ({
  route_pill: routePill,
  status,
  location,
  station_count: stationCount,
  id,
}) => {
  const { ref, abbrev, truncateStatus, replaceLocationWithUrl, isDone } =
    useSubwayStatusTextResizer(
      CONTRACTED_ALERT_MAX_HEIGHT,
      CONTRACTED_ALERT_FITTING_STEPS,
      id,
      status
    );

  let locationText: string | null;
  if (replaceLocationWithUrl) {
    locationText = ALERTS_URL;
  } else if (isAlertLocationMap(location)) {
    locationText = abbrev ? location.abbrev : location.full;
  } else {
    locationText = location;
  }

  if (truncateStatus) {
    const effect = firstWord(status);
    status =
      effect === "Bypassing"
        ? `Bypassing ${stationCount} ${stationCount === 1 ? "stop" : "stops"}`
        : effect;
  }

  return (
    <BasicAlert
      routePill={routePill}
      status={status}
      location={locationText}
      hideOverflow={isDone}
      ref={ref}
    />
  );
};

const ExtendedAlert: ComponentType<AlertWithID> = ({
  route_pill: routePill,
  status,
  location,
  id,
}) => {
  const { ref, abbrev, isDone } = useSubwayStatusTextResizer(
    EXTENDED_ALERT_MAX_HEIGHT,
    EXTENDED_ALERT_FITTING_STEPS,
    id,
    status
  );

  let locationText: string | null;
  if (isAlertLocationMap(location)) {
    locationText = abbrev ? location.abbrev : location.full;
  } else {
    locationText = location;
  }

  return (
    <BasicAlert
      routePill={routePill}
      status={status}
      location={locationText}
      hideOverflow={isDone}
      ref={ref}
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

    let sizerClassName = "subway-status_alert-sizer";
    if (hideOverflow) {
      sizerClassName = classWithModifier(sizerClassName, "hide-overflow");
    }

    let textContainerClassName = "subway-status_alert_text-container";
    const textContainerModifiers: string[] = [];
    if (hideOverflow) {
      textContainerModifiers.push("hide-overflow");
    }

    if (routePill?.branches) {
      textContainerModifiers.push(`${routePill.branches.length}-branches`);
    }

    textContainerClassName = classWithModifiers(
      textContainerClassName,
      textContainerModifiers
    );

    let statusTextClassName = "subway-status_alert_status-text";
    if (status === NORMAL_STATUS) {
      statusTextClassName = classWithModifier(
        statusTextClassName,
        "normal-service"
      );
    }

    return (
      <div className={containerClassName}>
        <div className={sizerClassName} ref={ref}>
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
    const LinePill = STRING_TO_SVG[`${routePill.color[0]}l`]
    return (
      <LinePill width="144" height="74" color={getHexColor(routePill.color)} />
    );
  }
};

const GLBranchPillGroup: ComponentType<Pick<GLMultiPill, "branches">> = ({
  branches: [firstBranch, ...rest],
}) => {
  const ComboLinePill = STRING_TO_SVG[`gl-${firstBranch}`]

  return (
    <>
      <ComboLinePill width="203" height="74" color={getHexColor("green")} />
      {rest.map((branch) => {
        const BranchPill = STRING_TO_SVG[`green-${branch}-circle`]
        return <BranchPill width="74" height="74" color={getHexColor("green")} className="branch-icon" key={ branch }/>
      })}
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

const isExtendedWithNoLocation = (
  section: Section
): section is ExtendedSection => isExtended(section) && !section.alert.location;

export default LcdSubwayStatus;

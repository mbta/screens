import { type ComponentType } from "react";
import { classWithModifier, classWithModifiers } from "Util/utils";
import { STRING_TO_SVG, getHexColor } from "Util/svg_utils";
import {
  Alert,
  ExtendedSection,
  MultiPill,
  Section,
  SubwayStatusData,
  SubwayStatusPill,
  adjustAlertForContractedStatus,
  isContracted,
  isContractedWith1Alert,
  isExtended,
  isMultiPill,
  useSubwayStatusTextResizer,
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
  const alerts =
    section.type === "contracted"
      ? section.alerts.map(adjustAlertForContractedStatus)
      : [section.alert];

  return (
    <div
      className={classWithModifiers("subway-status_status", [
        section.type,
        alerts.length === 1 ? "one-alert" : "two-alerts",
        alerts?.[1]?.route_pill && "has-second-pill",
      ])}
    >
      {alerts.map((alert, index) => (
        <BasicAlert alert={alert} type={section.type} key={index} />
      ))}
      {showRule && <div className="subway-status_status_rule" />}
    </div>
  );
};

const NORMAL_STATUS = "Normal Service";

interface BasicAlertProps {
  alert: Alert;
  type: "contracted" | "extended";
}

const BasicAlert = ({ alert, type }: BasicAlertProps) => {
  const { ref, status, location, isLastStep } = useSubwayStatusTextResizer(
    alert,
    type,
  );

  const containerClassName = classWithModifier(
    "subway-status_alert",
    alert.route_pill ? "has-pill" : "no-pill",
  );

  const sizerClassName = classWithModifier(
    "subway-status_alert-sizer",
    isLastStep && "hide-overflow",
  );

  const textContainerClassName = classWithModifiers(
    "subway-status_alert_text-container",
    [
      isLastStep && "hide-overflow",
      alert.route_pill?.branches &&
        `${alert.route_pill.branches.length}-branches`,
    ],
  );

  const statusTextClassName = classWithModifier(
    "subway-status_alert_status-text",
    status === NORMAL_STATUS && "normal-service",
  );

  return (
    <div className={containerClassName}>
      <div className={sizerClassName} ref={ref}>
        <div className="subway-status_alert_route-pill-container">
          {alert.route_pill && (
            <SubwayStatusRoutePill routePill={alert.route_pill} />
          )}
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
};

const SubwayStatusRoutePill: ComponentType<{ routePill: SubwayStatusPill }> = ({
  routePill,
}) => {
  if (isMultiPill(routePill)) {
    const sortedUniqueBranches = Array.from(new Set(routePill.branches)).sort();
    return (
      <BranchPillGroup
        color={routePill.color}
        branches={sortedUniqueBranches}
      />
    );
  } else {
    const LinePill = STRING_TO_SVG[`${routePill.color[0]}l`];
    return (
      <LinePill width="144" height="74" color={getHexColor(routePill.color)} />
    );
  }
};

const BranchPillGroup: ComponentType<Pick<MultiPill, "branches" | "color">> = ({
  color,
  branches: [firstBranch, ...rest],
}) => {
  // Determine the line prefix based on color
  const linePrefix = color === "green" ? "gl" : color === "red" ? "rl" : color;
  const ComboLinePill = STRING_TO_SVG[`${linePrefix}-${firstBranch}`];

  return (
    <>
      <ComboLinePill width="203" height="74" color={getHexColor(color)} />
      {rest.map((branch) => {
        const BranchPill = STRING_TO_SVG[`${color}-${branch}-circle`];
        return (
          <BranchPill
            width="74"
            height="74"
            color={getHexColor(color)}
            className="branch-icon"
            key={branch}
          />
        );
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
  section: Section,
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
  section: Section,
): section is ExtendedSection => isExtended(section) && !section.alert.location;

export default LcdSubwayStatus;

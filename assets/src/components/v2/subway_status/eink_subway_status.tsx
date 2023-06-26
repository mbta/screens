import React, { ComponentType, forwardRef } from "react";
import { classWithModifier, firstWord, imagePath } from "Util/util";
import {
  Alert,
  ContractedSection,
  GLBranch,
  GLMultiPill,
  LineColor,
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
import EinkSubwayStatusPill from "../bundled_svg/eink_subway_status_pill";

////////////////
// COMPONENTS //
////////////////

const EinkSubwayStatus: ComponentType<SubwayStatusData> = (props) => {
  const { blue, orange, red, green } = props;

  return (
    <div className="subway-status">
      {shouldShowHeader(props) && (
        <span className="subway-status__header">Current Subway Service</span>
      )}
      <LineStatus section={blue} color={LineColor.Blue} />
      <LineStatus section={orange} color={LineColor.Orange} />
      <LineStatus section={red} color={LineColor.Red} />
      <LineStatus section={green} color={LineColor.Green} />
    </div>
  );
};

type LineStatusProps = { section: Section; color: LineColor };

const LineStatus: ComponentType<LineStatusProps> = ({ section, color }) => {
  let alerts: [Alert] | [Alert, Alert] = isContracted(section)
    ? section.alerts
    : [section.alert];

  const routePill = getRoutePillObject(section, color);
  const showInlineBranches =
    color === LineColor.Green &&
    ((isContracted(section) && section.alerts.length > 1) ||
      isExtended(section));

  return (
    <div
      className={classWithModifier(
        "subway-status_row",
        alerts.length === 1 ? "single" : "multi"
      )}
    >
      <div className="subway-status_route-pill-container">
        <SubwayStatusRoutePill routePill={routePill} />
      </div>
      <Status alerts={alerts} showInlineBranches={showInlineBranches} />
      <div className="subway-status_status_rule" />
    </div>
  );
};

type StatusProps = Pick<ContractedSection, "alerts"> & {
  showInlineBranches: boolean;
};

const Status: ComponentType<StatusProps> = ({ alerts, showInlineBranches }) => {
  return (
    <div className="subway-status_status">
      {alerts.map((alert, index) => {
        const adjustedAlert = adjustAlertForContractedStatus(alert);
        const id = getAlertID(adjustedAlert, "contracted", index);
        return (
          <AlertRow
            {...adjustedAlert}
            id={id}
            key={id}
            showInlineBranches={showInlineBranches}
          />
        );
      })}
    </div>
  );
};

interface AlertRowProps extends Alert {
  id: string;
  showInlineBranches: boolean;
}

const ALERTS_URL = "mbta.com/alerts";
const ALERT_FITTING_STEPS = [
  FittingStep.PerAlertEffect,
  FittingStep.Abbrev,
  FittingStep.FullSize,
];

const AlertRow: ComponentType<AlertRowProps> = ({
  route_pill: routePill,
  status,
  location,
  station_count: stationCount,
  id,
  showInlineBranches,
}) => {
  // row height is a little taller when there is an inline GL branch pill
  const rowHeight = showInlineBranches ? 70 : 65;
  const { ref, abbrev, truncateStatus, replaceLocationWithUrl } =
    useSubwayStatusTextResizer(rowHeight, ALERT_FITTING_STEPS, id, status);

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
      showInlineBranches={showInlineBranches}
      ref={ref}
    />
  );
};

const NORMAL_STATUS = "Normal Service";

interface BasicAlertProps extends Omit<Alert, "route_pill"> {
  routePill?: Alert["route_pill"];
  location: string | null;
  showInlineBranches: boolean;
}

const BasicAlert = forwardRef<HTMLDivElement, BasicAlertProps>(
  ({ routePill, status, location, showInlineBranches }, ref) => {
    let textContainerClassName = "subway-status_alert_text-container";

    if (status === NORMAL_STATUS) {
      textContainerClassName = classWithModifier(
        textContainerClassName,
        "normal-service"
      );
    }

    return (
      <div className="subway-status_alert">
        {showInlineBranches && routePill?.branches && (
          <div className="subway-status_alert_route-pill-container">
            <SubwayStatusRoutePill routePill={routePill} showInlineBranches />
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

const SubwayStatusRoutePill: ComponentType<{
  routePill: SubwayStatusPill;
  showInlineBranches?: boolean;
}> = ({ routePill, showInlineBranches }) => {
  // If there are branches, return a pill group with each branch icon.
  if (isGLMultiPill(routePill)) {
    const sortedUniqueBranches = Array.from(new Set(routePill.branches)).sort();
    return (
      <GLBranchPillGroup
        branches={sortedUniqueBranches}
        showInlineBranches={showInlineBranches}
      />
    );
  }

  // Return the route pill at the top of the section above alerts.
  return getStandardLinePillPath(routePill.color)
};

const GLBranchPillGroup: ComponentType<
  Pick<GLMultiPill, "branches"> & { showInlineBranches?: boolean }
> = ({ branches, showInlineBranches }) => {
  // We only inline route pills for GL branches.
  // Otherwise, we show a single route pill above alerts in each section.
  if (showInlineBranches) {
    return (
      <>
        {branches.map((branch) => getGLBranchLetterPillPath(branch)) }
      </>
    );
  }

  const [firstBranch, ...rest] = branches;
  return (
    <>
      {getGLComboPillPath(firstBranch)}
      {rest.map((branch) => getGLBranchLetterPillPath(branch))}
    </>
  );
};

/////////////
// HELPERS //
/////////////

// The header is displayed when every section has exactly 1 alert.
const shouldShowHeader = ({ blue, orange, red, green }: SubwayStatusData) => {
  return [blue, orange, red, green].every(
    (data) => isContractedWith1Alert(data) || isExtended(data)
  );
};

const getRoutePillObject = (
  section: Section,
  color: LineColor
): SubwayStatusPill => {
  // If the current section is `green` and there is only one alert, see if there are any branches
  // that can be added to the route pill. If no branches exist, the GL pill will be rendered with no branches.
  if (color === "green") {
    if (isContractedWith1Alert(section)) {
      return {
        color: color,
        branches: section.alerts.flatMap(
          (alert) => alert.route_pill?.branches ?? []
        ),
      };
    } else if (isExtended(section)) {
      return { color: color, branches: section.alert.route_pill?.branches };
    }
  }

  return { color: color };
};

const getStandardLinePillPath = (lineColor: LineColor) => (<EinkSubwayStatusPill pill={`${lineColor}-line`} className="pill-icon" />)

const getGLComboPillPath = (branch: GLBranch) => <EinkSubwayStatusPill pill={`gl-${branch}`} className="pill-icon" />

const getGLBranchLetterPillPath = (branch: GLBranch) => <EinkSubwayStatusPill pill={`green-${branch}-circle`} className="branch-icon" />


export default EinkSubwayStatus;

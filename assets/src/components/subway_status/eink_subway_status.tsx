import { type ComponentType } from "react";
import { classWithModifier } from "Util/utils";
import { STRING_TO_SVG } from "Util/svg_utils";
import {
  Alert,
  MultiPill,
  LineColor,
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
  const alerts: [Alert] | [Alert, Alert] = isContracted(section)
    ? section.alerts
    : [section.alert];

  const routePill = getRoutePillObject(section, color);
  const showInlineBranches =
    (color === LineColor.Green || color === LineColor.Red) &&
    isContracted(section) &&
    section.alerts.length > 1;

  return (
    <div
      className={classWithModifier(
        "subway-status_row",
        alerts.length === 1 ? "single" : "multi",
      )}
    >
      <div className="subway-status_route-pill-container">
        <SubwayStatusRoutePill routePill={routePill} />
      </div>
      <div className="subway-status_status">
        {alerts.map((alert, index) => {
          const adjustedAlert = adjustAlertForContractedStatus(alert);
          return (
            <BasicAlert
              alert={adjustedAlert}
              showInlineBranches={showInlineBranches}
              key={index}
            />
          );
        })}
      </div>
      <div className="subway-status_status_rule" />
    </div>
  );
};

const NORMAL_STATUS = "Normal Service";

interface BasicAlertProps {
  alert: Alert;
  showInlineBranches: boolean;
}

const BasicAlert = ({ alert, showInlineBranches }: BasicAlertProps) => {
  const { ref, status, location } = useSubwayStatusTextResizer(
    alert,
    "contracted",
  );
  const textContainerClassName = classWithModifier(
    "subway-status_alert_text-container",
    status === NORMAL_STATUS && "normal-service",
  );

  return (
    <div className="subway-status_alert" ref={ref}>
      {showInlineBranches && alert.route_pill?.branches && (
        <div className="subway-status_alert_route-pill-container">
          <SubwayStatusRoutePill
            routePill={alert.route_pill}
            showInlineBranches
          />
        </div>
      )}
      <div className={textContainerClassName}>
        {status && <span>{status}</span>}
        {location && (
          <span className="subway-status_alert_location-text">{location}</span>
        )}
      </div>
    </div>
  );
};

const SubwayStatusRoutePill: ComponentType<{
  routePill: SubwayStatusPill;
  showInlineBranches?: boolean;
}> = ({ routePill, showInlineBranches }) => {
  // If there are branches, return a pill group with each branch icon.
  if (isMultiPill(routePill)) {
    const sortedUniqueBranches = Array.from(new Set(routePill.branches)).sort();
    return (
      <BranchPillGroup
        color={routePill.color}
        branches={sortedUniqueBranches}
        showInlineBranches={showInlineBranches}
      />
    );
  }

  // Return the route pill at the top of the section above alerts.
  const LinePill = STRING_TO_SVG[`${routePill.color}-line`];
  return <LinePill height="65" />;
};

const BranchPillGroup: ComponentType<
  Pick<MultiPill, "branches" | "color"> & { showInlineBranches?: boolean }
> = ({ color, branches, showInlineBranches }) => {
  // We only inline route pills for GL branches.
  // Otherwise, we show a single route pill above alerts in each section.
  if (showInlineBranches) {
    return (
      <>
        {branches.map((branch) => {
          const LinePill = STRING_TO_SVG[`${color}-${branch}-circle`];
          return (
            <LinePill
              width="64"
              height="64"
              key={branch}
              className="branch-icon"
            />
          );
        })}
      </>
    );
  }

  const [firstBranch, ...rest] = branches;
  const ComboLinePill = STRING_TO_SVG[`${color}-line-${firstBranch}`];
  return (
    <>
      <ComboLinePill width="404" height="64" className="branch-icon" />
      {rest.map((branch) => {
        const BranchLinePill = STRING_TO_SVG[`${color}-${branch}-circle`];
        return (
          <BranchLinePill
            width="64"
            height="64"
            key={branch}
            className="branch-icon"
          />
        );
      })}
    </>
  );
};

/////////////
// HELPERS //
/////////////

// The header is displayed when every section has exactly 1 alert.
const shouldShowHeader = ({ blue, orange, red, green }: SubwayStatusData) => {
  return [blue, orange, red, green].every(
    (data) => isContractedWith1Alert(data) || isExtended(data),
  );
};

const getRoutePillObject = (
  section: Section,
  color: LineColor,
): SubwayStatusPill => {
  // If there is only one alert, see if there are any branches that should be added
  // to the route pill. If no branches exist, the pill will be rendered with no branches.
  if (isContractedWith1Alert(section)) {
    return {
      color: color,
      branches: section.alerts.flatMap(
        (alert) => alert.route_pill?.branches ?? [],
      ),
    };
  } else if (isExtended(section)) {
    return { color: color, branches: section.alert.route_pill?.branches };
  }

  return { color: color };
};

export default EinkSubwayStatus;

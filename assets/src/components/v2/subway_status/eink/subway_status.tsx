import React, { ComponentType, forwardRef } from "react";
import { classWithModifier, imagePath } from "Util/util";
import useTextResizer from "Hooks/v2/use_text_resizer";
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
  firstWord,
  getAlertID,
  isAlertLocationMap,
  isContractedWith1Alert,
  isExtended,
  isGLMultiPill,
} from "../subway_status_common";

////////////////
// COMPONENTS //
////////////////

const SubwayStatus: ComponentType<SubwayStatusData> = (props) => {
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
  let row;
  switch (section.type) {
    case "contracted":
      row = <ContractedStatus alerts={section.alerts} />;
      break;
    case "extended":
      row = <ContractedStatus alerts={[section.alert]} />;
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
const CONTRACTED_ROW_HEIGHT = 70;

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

const NORMAL_STATUS = "Normal Service";

interface BasicAlertProps extends Omit<Alert, "route_pill"> {
  routePill?: Alert["route_pill"];
  location: string | null;
  hideOverflow?: boolean;
}

const BasicAlert = forwardRef<HTMLDivElement, BasicAlertProps>(
  ({ routePill, status, location }, ref) => {
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
  branches,
}) => {
  return (
    <>
      {branches.map((branch) => (
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

const shouldShowHeader = ({ blue, orange, red, green }: SubwayStatusData) => {
  return [blue, orange, red, green].every(
    (data) => isContractedWith1Alert(data) || isExtended(data)
  );
};

const getStandardLinePillPath = (lineColor: LineColor) =>
  pillPath(`${lineColor}-line.svg`);

const getGLComboPillPath = (branch: GLBranch) => pillPath(`gl-${branch}.svg`);

const getGLBranchLetterPillPath = (branch: GLBranch) =>
  pillPath(`green-${branch}-circle.svg`);

const pillPath = (pillFilename: string) =>
  imagePath(`pills/eink/${pillFilename}`);

export default SubwayStatus;

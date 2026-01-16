import { type ComponentType } from "react";
import * as fp from "lodash/fp";
import { classWithModifier } from "Util/utils";
import {
  Alert,
  ExtendedSection,
  Section,
  SectionType,
  SubwayStatusData,
  SubwayStatusPill,
  adjustAlertForContractedStatus,
  isExtended,
  useSubwayStatusTextResizer,
} from "./subway_status_common";

////////////////
// COMPONENTS //
////////////////

const LcdSubwayStatus: ComponentType<SubwayStatusData> = (props) => {
  const { blue, orange, red, green } = cleanUpServerData(props);

  return (
    <div className="subway-status">
      {showHeader([blue, orange, red, green]) && (
        <div className="subway-status__header">Subway Status</div>
      )}
      <LineStatus section={blue} />
      <LineStatus section={orange} />
      <LineStatus section={red} />
      <LineStatus section={green} />
    </div>
  );
};

type LineStatusProps = { section: Section };

const LineStatus: ComponentType<LineStatusProps> = ({ section }) => {
  const alerts =
    section.type === "contracted"
      ? section.alerts.map(adjustAlertForContractedStatus)
      : [section.alert];

  return (
    <div className="subway-status__line">
      {alerts.map((alert, index) => (
        <BasicAlert alert={alert} type={section.type} key={index} />
      ))}
    </div>
  );
};

const NORMAL_STATUS = "Normal Service";

interface BasicAlertProps {
  alert: Alert;
  type: SectionType;
}

const BasicAlert = ({ alert, type }: BasicAlertProps) => {
  const { ref, status, location } = useSubwayStatusTextResizer(alert, type);

  return (
    <div className="subway-status__alert" ref={ref}>
      <div className="subway-status__pill-container">
        {alert.route_pill && <RoutePill routePill={alert.route_pill} />}
      </div>
      <div className={classWithModifier("subway-status__text-container", type)}>
        {status && (
          <span
            className={classWithModifier(
              "subway-status__status-text",
              status === NORMAL_STATUS && "normal",
            )}
          >
            {status}
          </span>
        )}
        {location && (
          <span className="subway-status__location-text">{location}</span>
        )}
      </div>
    </div>
  );
};

interface RoutePillProps {
  routePill: SubwayStatusPill;
}

const RoutePill = ({
  routePill: { color, text, branches },
}: RoutePillProps) => {
  return (
    <span className={classWithModifier("subway-status__route-pill", color)}>
      <span className="subway-status__route-pill__main">{text}</span>
      {branches?.map((branch) => (
        <span className="subway-status__route-pill__branch" key={branch}>
          {branch.toUpperCase()}
        </span>
      ))}
    </span>
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

const isExtendedWithNoLocation = (
  section: Section,
): section is ExtendedSection => isExtended(section) && !section.alert.location;

const showHeader = (sections: Section[]) => {
  // Note: This computation is tied to the CSS, and may need to change when it does.
  const height = fp.sumBy((section) => {
    if (section.type === "contracted") {
      return section.alerts.length === 1 ? 120 : 216;
    } else {
      return 160;
    }
  }, sections);
  return height < 530;
};

export default LcdSubwayStatus;

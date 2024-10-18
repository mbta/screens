import React from "react";
import NormalService from "Images/svgr_bundled/normal-service.svg";
import AccessibilityAlert from "Images/svgr_bundled/accessibility-alert.svg";

interface InStationSummaryProps {
  alerts: string[];
}

const InStationSummary = ({ alerts }: InStationSummaryProps) => {
  const summaryText = alerts.length
    ? ""
    : "All elevators at this station are currently working";

  return (
    <>
      <div className="in-station-summary">
        <span className="text">{summaryText}</span>
        <span>
          <NormalService height={72} width={72} fill="#145A06" />
        </span>
      </div>
      <hr />
    </>
  );
};

interface OutsideAlertListProps {
  alerts: string[];
}

const OutsideAlertList = (_props: OutsideAlertListProps) => {
  return (
    <div className="outside-alert-list">
      <div className="header">
        <span>MBTA Elevator Closures</span>
        <span>
          <AccessibilityAlert height={128} width={128} />
        </span>
      </div>
    </div>
  );
};

interface Props {
  id: string;
  in_station_alerts: string[];
  outside_alerts: string[];
}

const ElevatorClosures: React.ComponentType<Props> = ({
  in_station_alerts: inStationAlerts,
  outside_alerts: outsideAlerts,
}: Props) => {
  return (
    <div className="elevator-closures">
      <InStationSummary alerts={inStationAlerts} />
      <OutsideAlertList alerts={outsideAlerts} />
    </div>
  );
};

export default ElevatorClosures;

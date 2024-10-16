import React from "react";
import { formatTimeString } from "Util/util";
import NormalService from "Images/svgr_bundled/normal-service.svg";
import AccessibilityAlert from "Images/svgr_bundled/accessibility-alert.svg";

interface HeaderProps {
  id: string;
  time: string;
}

const Header = ({ id, time }: HeaderProps) => {
  return (
    <div className="screen-header">
      <span className="header__id">Elevator {id}</span>
      <span className="header__time">{formatTimeString(time)}</span>
    </div>
  );
};
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

const Footer = () => {
  return (
    <div className="footer">
      <span>
        For more info and alternate paths: mbta.com/alerts/access or (617)
        222-2828
      </span>
    </div>
  );
};

interface Props {
  id: string;
  time: string;
  in_station_alerts: string[];
  outside_alerts: string[];
}

const ElevatorClosures: React.ComponentType<Props> = ({
  id,
  time,
  in_station_alerts: inStationAlerts,
  outside_alerts: outsideAlerts,
}: Props) => {
  return (
    <div className="elevator-closures">
      <Header id={id} time={time} />
      <InStationSummary alerts={inStationAlerts} />
      <OutsideAlertList alerts={outsideAlerts} />
      <Footer />
    </div>
  );
};

export default ElevatorClosures;

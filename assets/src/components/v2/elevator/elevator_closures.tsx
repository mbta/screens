import React from "react";
import { formatTimeString } from "Util/util";
import NormalService from "Images/svgr_bundled/normal-service.svg";

interface HeaderProps {
  id: string;
  time: string;
}

const Header = ({ id, time }: HeaderProps) => {
  return (
    <div className="header">
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
}: Props) => {
  return (
    <div className="elevator-closures">
      <Header id={id} time={time} />
      <InStationSummary alerts={inStationAlerts} />
    </div>
  );
};

export default ElevatorClosures;

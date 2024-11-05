import React, { useLayoutEffect, useRef, useState } from "react";
import NormalService from "Images/svgr_bundled/normal-service.svg";
import AccessibilityAlert from "Images/svgr_bundled/accessibility-alert.svg";

type ElevatorClosure = {
  station_name: string;
  routes: string[];
  id: string;
  elevator_name: string;
  elevator_id: string;
  description: string;
  header_text: string;
};

interface ClosureRowProps {
  alert: ElevatorClosure;
}

const ClosureRow = ({ alert }: ClosureRowProps) => {
  const { station_name, elevator_name, elevator_id } = alert;
  return (
    <div className="alert-row">
      <hr />
      <div className="alert-row__station-name">{station_name}</div>
      <div className="alert-row__elevator-name">
        {elevator_name} ({elevator_id})
      </div>
    </div>
  );
};

interface InStationSummaryProps {
  alerts: ElevatorClosure[];
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
  alerts: ElevatorClosure[];
}

const OutsideAlertList = ({ alerts }: OutsideAlertListProps) => {
  const ref = useRef<HTMLDivElement>(null);
  const maxHeight = 904;
  const [keepChecking, setKeepChecking] = useState(true);
  const [renderedAlerts, setRenderedAlerts] = useState<ElevatorClosure[]>([]);
  const [overflowingAlerts, setOverflowingAlerts] =
    useState<ElevatorClosure[]>(alerts);

  useLayoutEffect(() => {
    if (!ref.current || !keepChecking) return;

    if (ref.current.clientHeight <= maxHeight && overflowingAlerts.length) {
      setRenderedAlerts(renderedAlerts.concat(overflowingAlerts[0]));
      setOverflowingAlerts(overflowingAlerts.slice(1));
    }

    if (ref.current.clientHeight > maxHeight) {
      setRenderedAlerts(renderedAlerts.slice(0, -1));
      setOverflowingAlerts(
        renderedAlerts.slice(0, -1).concat(overflowingAlerts),
      );
      setKeepChecking(false);
    }
  });

  return (
    <div className="outside-alert-list">
      <div className="header">
        <div className="header__title">MBTA Elevator Closures</div>
        <div>
          <AccessibilityAlert height={128} width={128} />
        </div>
      </div>
      <div className="alert-list-container">
        <div className="alert-list" ref={ref}>
          {renderedAlerts.map((alert) => (
            <ClosureRow alert={alert} key={alert.id} />
          ))}
        </div>
      </div>
      <div className="paging-info-container">
        +{overflowingAlerts.length} more elevators
      </div>
    </div>
  );
};

interface Props {
  id: string;
  in_station_alerts: ElevatorClosure[];
  outside_alerts: ElevatorClosure[];
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

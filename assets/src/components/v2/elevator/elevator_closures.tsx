import React, {
  ComponentType,
  useEffect,
  useLayoutEffect,
  useRef,
  useState,
} from "react";
import NormalService from "Images/svgr_bundled/normal-service.svg";
import AccessibilityAlert from "Images/svgr_bundled/accessibility-alert.svg";
import makePersistent, { WrappedComponentProps } from "../persistent_wrapper";

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

interface OutsideAlertListProps extends WrappedComponentProps {
  alerts: ElevatorClosure[];
  lastUpdate: number | null;
}

const OutsideAlertList = ({
  alerts,
  lastUpdate,
  onFinish,
}: OutsideAlertListProps) => {
  const [isResizing, setIsResizing] = useState(true);
  const [visibleAlerts, setVisibleAlerts] = useState<ElevatorClosure[]>([]);
  const [alertsQueue, setAlertsQueue] = useState<ElevatorClosure[]>(alerts);
  const [isFirstRender, setIsFirstRender] = useState(true);
  const ref = useRef<HTMLDivElement>(null);

  useEffect(() => {
    // Give the page a sec on first render
    if (isFirstRender) {
      setIsFirstRender(false);
      return;
    }
    // If leftover alerts list is empty here, onFinish() was called in last render.
    // Reset the list back to props to pick up any changes.
    else if (alertsQueue.length === 0) {
      setAlertsQueue(alerts);
    }

    // If we are not already resizing the list, reset it so it will start resizing.
    if (!isResizing) {
      setVisibleAlerts([]);
      setIsResizing(true);
    }
  }, [lastUpdate]);

  useLayoutEffect(() => {
    if (!ref.current || !isResizing || isFirstRender) return;

    const maxHeight = 904;

    // If we have leftover alerts and still have room in the list, add an alert to render.
    if (ref.current.clientHeight < maxHeight && alertsQueue.length) {
      setVisibleAlerts([...visibleAlerts, alertsQueue[0]]);
      setAlertsQueue(alertsQueue.slice(1));
    }
    // If adding an alert made the list too big, remove the last alert, add it back to leftover, and stop resizing.
    else if (ref.current.clientHeight > maxHeight) {
      setVisibleAlerts(visibleAlerts.slice(0, -1));
      setAlertsQueue(visibleAlerts.slice(-1).concat(alertsQueue));
      setIsResizing(false);
    }
    // If we are done resizing and there are no more alerts to page through, trigger a prop update.
    else if (alertsQueue.length === 0) {
      onFinish();
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
          {visibleAlerts.map((alert) => (
            <ClosureRow alert={alert} key={alert.id} />
          ))}
        </div>
      </div>
      <div className="paging-info-container">
        +{alerts.length - visibleAlerts.length} more elevators
      </div>
    </div>
  );
};

interface Props extends WrappedComponentProps {
  id: string;
  in_station_alerts: ElevatorClosure[];
  outside_alerts: ElevatorClosure[];
}

const ElevatorClosures: React.ComponentType<Props> = ({
  in_station_alerts: inStationAlerts,
  outside_alerts: outsideAlerts,
  lastUpdate,
  onFinish,
}: Props) => {
  return (
    <div className="elevator-closures">
      <InStationSummary alerts={inStationAlerts} />
      <OutsideAlertList
        alerts={outsideAlerts}
        lastUpdate={lastUpdate}
        onFinish={onFinish}
      />
    </div>
  );
};

export default makePersistent(
  ElevatorClosures as ComponentType<WrappedComponentProps>,
);

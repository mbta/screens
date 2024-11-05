import React, {
  ComponentType,
  useEffect,
  useLayoutEffect,
  useRef,
  useState,
} from "react";
import NormalService from "Images/svgr_bundled/normal-service.svg";
import AccessibilityAlert from "Images/svgr_bundled/accessibility-alert.svg";
import PagingDotUnselected from "Images/svgr_bundled/paging_dot_unselected.svg";
import PagingDotSelected from "Images/svgr_bundled/paging_dot_selected.svg";
import makePersistent, { WrappedComponentProps } from "../persistent_wrapper";
import RoutePill, { routePillKey, type Pill } from "../departures/route_pill";

type ElevatorClosure = {
  station_name: string;
  routes: Pill[];
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
  const { station_name, elevator_name, elevator_id, routes } = alert;

  return (
    <div className="alert-row">
      <div className="alert-row__name-and-pills">
        {routes.map((route) => (
          <RoutePill pill={route} key={routePillKey(route)} />
        ))}
        <div className="alert-row__station-name">{station_name}</div>
      </div>
      <div className="alert-row__elevator-name">
        {elevator_name} ({elevator_id})
      </div>
      <hr />
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
  const [visibleAlerts, setVisibleAlerts] = useState<ElevatorClosure[]>([]);
  const [alertsQueue, setAlertsQueue] = useState<ElevatorClosure[]>(alerts);
  const [isFirstRender, setIsFirstRender] = useState(true);
  const [pages, setPages] = useState<ElevatorClosure[][]>([]);
  const [pageIndex, setPageIndex] = useState(0);
  // Value that tells hooks if useLayoutEffect is actively running
  const [isResizing, setIsResizing] = useState(true);
  // Value that forces a hook to add a page to state
  const [addPage, setAddPage] = useState(true);
  // Value that tells all hooks we are done until onFinish is called
  const [doneGettingPages, setDoneGettingPages] = useState(false);
  const ref = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (lastUpdate != null) {
      if (isFirstRender) {
        setIsFirstRender(false);
      } else {
        setPageIndex((i) => i + 1);
      }
    }
  }, [lastUpdate]);

  useEffect(() => {
    if (pageIndex === pages.length - 1) {
      onFinish();
    }
  }, [pageIndex]);

  useEffect(() => {
    // Make sure we aren't actively calculating a page before adding to list
    if (!isResizing) {
      setPages([...pages, visibleAlerts]);
      // If queue isn't empty, there are more pages to calculate
      if (alertsQueue.length > 0) {
        setVisibleAlerts([]);
        setIsResizing(true);
      }
      // Done paging and safe to render content
      else {
        setDoneGettingPages(true);
      }
    }
  }, [addPage]);

  useLayoutEffect(() => {
    if (!ref.current || !isResizing) return;

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
      setAddPage(!addPage);
    } else {
      setIsResizing(false);
      setAddPage(!addPage);
    }
  }, [visibleAlerts]);

  const alertsToRender = doneGettingPages ? pages[pageIndex] : visibleAlerts;
  return (
    <div className="outside-alert-list">
      <div className="header">
        <div className="header__title">MBTA Elevator Closures</div>
        <div>
          <AccessibilityAlert height={128} width={128} />
        </div>
      </div>
      <hr />
      <div className="alert-list-container">
        {
          <div className="alert-list" ref={ref}>
            {alertsToRender.map((alert) => (
              <ClosureRow alert={alert} key={alert.id} />
            ))}
          </div>
        }
      </div>
      {pages.length && (
        <div className="paging-info-container">
          <div>+{alerts.length - pages[pageIndex].length} more elevators</div>
          <div className="paging-indicators">
            {[...Array(pages.length)].map((_, i) => {
              return pageIndex === i ? (
                <PagingDotSelected key={i} />
              ) : (
                <PagingDotUnselected key={i} />
              );
            })}
          </div>
        </div>
      )}
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

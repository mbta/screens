import React, {
  ComponentType,
  useEffect,
  useLayoutEffect,
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
      <hr className="thin" />
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
      <hr className="thick" />
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
  const [isFirstRender, setIsFirstRender] = useState(true);
  const [pageIndex, setPageIndex] = useState(0);
  const [numPages, setNumPages] = useState(0);

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
    if (pageIndex === numPages - 1) {
      onFinish();
    }
  }, [pageIndex]);

  useLayoutEffect(() => {
    const closureRows = document.getElementsByClassName("alert-row");
    const uniqueOffsets = Array.from(closureRows)
      .map((closure) => (closure as HTMLDivElement).offsetLeft)
      .filter((val, i, self) => self.indexOf(val) === i);

    setNumPages(uniqueOffsets.length);
  }, []);

  return (
    <div className="outside-alert-list">
      <div className="header-container">
        <div className="header">
          <div className="header__title">MBTA Elevator Closures</div>
          <div>
            <AccessibilityAlert height={128} width={128} />
          </div>
        </div>
        <hr className="thin" />
      </div>
      <div className="alert-list-container">
        {
          <div
            className="alert-list"
            style={
              {
                "--alert-list-offset": pageIndex,
              } as React.CSSProperties
            }
          >
            {alerts.map((alert) => (
              <ClosureRow alert={alert} key={alert.id} />
            ))}
          </div>
        }
      </div>
      <div className="paging-info-container">
        <div>+{alerts.length} more elevators</div>
        <div className="paging-indicators">
          {[...Array(numPages)].map((_, i) => {
            return pageIndex === i ? (
              <PagingDotSelected key={i} />
            ) : (
              <PagingDotUnselected key={i} />
            );
          })}
        </div>
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

import React, {
  ComponentType,
  useEffect,
  useLayoutEffect,
  useMemo,
  useState,
} from "react";
import cx from "classnames";
import NormalService from "Images/svgr_bundled/normal-service.svg";
import AccessibilityAlert from "Images/svgr_bundled/accessibility-alert.svg";
import PagingDotUnselected from "Images/svgr_bundled/paging_dot_unselected.svg";
import PagingDotSelected from "Images/svgr_bundled/paging_dot_selected.svg";
import makePersistent, { WrappedComponentProps } from "../persistent_wrapper";
import RoutePill, { routePillKey, type Pill } from "../departures/route_pill";

type StationWithAlert = {
  id: string;
  name: string;
  routes: Pill[];
  alerts: ElevatorClosure[];
};

type ElevatorClosure = {
  id: string;
  elevator_name: string;
  elevator_id: string;
  description: string;
  header_text: string;
};

interface AlertRowProps {
  station: StationWithAlert;
}

const AlertRow = ({ station }: AlertRowProps) => {
  const { name, alerts, routes, id } = station;

  return (
    <div className="alert-row">
      <div className="alert-row__name-and-pills">
        {routes.map((route) => (
          <RoutePill pill={route} key={`${routePillKey(route)}-${id}`} />
        ))}
        <div className="alert-row__station-name">{name}</div>
      </div>
      {alerts.map((alert) => (
        <div
          key={alert.id}
          className={cx("alert-row__elevator-name", {
            "list-item": alerts.length > 1,
          })}
        >
          {alert.elevator_name} ({alert.elevator_id})
        </div>
      ))}
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
  stations: StationWithAlert[];
  lastUpdate: number | null;
}

const OutsideAlertList = ({
  stations,
  lastUpdate,
  onFinish,
}: OutsideAlertListProps) => {
  const [isFirstRender, setIsFirstRender] = useState(true);
  const [pageIndex, setPageIndex] = useState(0);

  // Each value represents the pageIndex the row is visible on
  const [rowPageIndexes, setRowPageIndexes] = useState<number[]>([]);

  const [numPages, numOffsetRows] = useMemo(
    () => [
      rowPageIndexes.filter((val, i, self) => self.indexOf(val) === i).length,
      rowPageIndexes.filter((offset) => offset !== pageIndex).length,
    ],
    [rowPageIndexes],
  );

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
    const alertRows = Array.from(document.getElementsByClassName("alert-row"));
    const screenWidth = 1080;
    const totalXMargins = 48;

    const rowPageIndexes = alertRows.map((alert) => {
      const val = (alert as HTMLDivElement).offsetLeft - totalXMargins;
      return val / screenWidth;
    });

    setRowPageIndexes(rowPageIndexes);
  }, [stations]);

  const getPagingIndicators = (num: number) => {
    const indicators: JSX.Element[] = [];
    for (let i = 0; i < num; i++) {
      const indicator =
        pageIndex === i ? (
          <PagingDotSelected key={i} />
        ) : (
          <PagingDotUnselected key={i} />
        );
      indicators.push(indicator);
    }

    return indicators;
  };

  return (
    <div className="outside-alert-list">
      <div className="header-container">
        <div className="header">
          <div className="header__title">MBTA Elevator Closures</div>
          <div>
            <AccessibilityAlert height={128} width={155} />
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
            {stations.map((station) => (
              <AlertRow station={station} key={station.id} />
            ))}
          </div>
        }
      </div>
      <div className="paging-info-container">
        <div>+{numOffsetRows} more elevators</div>
        <div className="paging-indicators">{getPagingIndicators(numPages)}</div>
      </div>
    </div>
  );
};

interface Props extends WrappedComponentProps {
  id: string;
  in_station_alerts: ElevatorClosure[];
  other_stations_with_alerts: StationWithAlert[];
}

const ElevatorClosures: React.ComponentType<Props> = ({
  other_stations_with_alerts: otherStationsWithAlerts,
  in_station_alerts: inStationAlerts,
  lastUpdate,
  onFinish,
}: Props) => {
  return (
    <div className="elevator-closures">
      <InStationSummary alerts={inStationAlerts} />
      <OutsideAlertList
        stations={otherStationsWithAlerts}
        lastUpdate={lastUpdate}
        onFinish={onFinish}
      />
    </div>
  );
};

export default makePersistent(
  ElevatorClosures as ComponentType<WrappedComponentProps>,
);

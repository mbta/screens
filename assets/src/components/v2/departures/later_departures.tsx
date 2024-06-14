import React, {
  useEffect,
  useLayoutEffect,
  useMemo,
  useRef,
  useState,
} from "react";
import _ from "lodash";
import cx from "classnames";

import { hasOverflowX } from "Util/util";
import useRefreshRate from "Hooks/v2/use_refresh_rate";

import DepartureRow from "./departure_row";
import RoutePill from "./route_pill";

const MAX_LATER_DEPARTURES = 5;

// "Magic" number carried over from Solari. Prevents a Later Departures
// component from paging through departures very slowly when there are only a
// few later departures
const MAX_PAGE_RATE_MS = 3750;

const LaterDepatures = ({ rows }: { rows: DepartureRow[] }) => {
  const { refreshRateMs } = useRefreshRate();
  const [limit, setLimit] = useState(MAX_LATER_DEPARTURES);
  const departures = useMemo(() => _.take(rows, limit), [rows, limit]);

  const ref = useRef<HTMLDivElement>(null);
  const [currentDepartureIdx, setCurrentDepartureIdx] = useState(0);

  useLayoutEffect(() => {
    if (hasOverflowX(ref)) {
      setLimit(Math.max(0, limit - 1));
    }
  }, [limit]);

  useEffect(() => {
    if (departures.length < 2) return;

    const pageDurationMs = Math.min(
      MAX_PAGE_RATE_MS,
      refreshRateMs / departures.length,
    );

    const interval = setInterval(() => {
      setCurrentDepartureIdx((i) => (i + 1) % departures.length);
    }, pageDurationMs);

    return () => clearInterval(interval);
  }, [refreshRateMs, departures.length]);

  return (
    <div
      className="later-departures__carousel"
      style={
        {
          "--later-departures-offset": currentDepartureIdx,
        } as React.CSSProperties
      }
    >
      {departures.map((departure, i) => (
        <div className="later-departures" key={departure.id}>
          <div className="later-departures__header" ref={ref}>
            <h3>Later Departures</h3>
            <ol>
              {departures.map((d, j) => (
                <li
                  key={d.id}
                  className={cx({
                    "later-departures__route--selected": i === j,
                  })}
                >
                  <RoutePill
                    pill={d.route}
                    outline={i !== j}
                    useRouteAbbrev={true}
                  />
                </li>
              ))}
            </ol>
          </div>
          <div>
            <DepartureRow {...departure} />
          </div>
        </div>
      ))}
    </div>
  );
};

export default LaterDepatures;

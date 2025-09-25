import {
  type CSSProperties,
  useEffect,
  useLayoutEffect,
  useMemo,
  useRef,
  useState,
} from "react";
import _ from "lodash";
import cx from "classnames";

import { hasOverflowX } from "Util/utils";
import useRefreshRate from "Hooks/use_refresh_rate";

import DepartureRow from "./departure_row";
import RoutePill from "./route_pill";

// Breakpoint where folding departures into Later Departures is likely to save
// space rather than take up more of it. Below this number of Later Departures,
// the component is not used, even if enabled.
export const MIN_LATER_DEPARTURES = 3;

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
    if (ref.current && hasOverflowX(ref.current)) {
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
    <div className="later-departures">
      <div className="later-departures__header" ref={ref}>
        <h3>Later Departures</h3>
        <ol>
          {departures.map((departure, index) => (
            <li
              key={departure.id}
              className={cx({
                "later-departures__route--selected":
                  index === currentDepartureIdx,
              })}
            >
              <RoutePill
                pill={departure.route}
                outline={index !== currentDepartureIdx}
                useRouteAbbrev={true}
              />
            </li>
          ))}
        </ol>
      </div>

      <div
        className="later-departures__carousel"
        style={
          {
            "--later-departures-offset": currentDepartureIdx,
          } as CSSProperties
        }
      >
        {departures.map((departure) => (
          <DepartureRow key={departure.id} {...departure} />
        ))}
      </div>
    </div>
  );
};

export default LaterDepatures;

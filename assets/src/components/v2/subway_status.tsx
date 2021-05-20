import React, { useState, useLayoutEffect, useRef } from "react";

import RoutePill from "Components/v2/departures/route_pill";
import { classWithModifier, imagePath } from "Util/util";

const iconForRoute = (routeId) => {
  return imagePath(
    {
      "Green-B": "gl-b-color.svg",
      "Green-C": "gl-c-color.svg",
      "Green-D": "gl-d-color.svg",
      "Green-E": "gl-e-color.svg",
    }[routeId]
  );
};

const SubwayStatusNormalRow = ({ route, status, location, branch }) => {
  const [abbreviate, setAbbreviate] = useState(false);
  const ref = useRef(null);

  useLayoutEffect(() => {
    if (ref.current) {
      if (!abbreviate && ref.current.clientHeight > 122) {
        setAbbreviate(true);
      }
    }
  });

  return (
    <div className="subway-status-row" ref={ref}>
      <div className="subway-status-row__route">
        <RoutePill {...route} />
      </div>
      {branch && (
        <div className="subway-status-row__branch">
          <img
            className="subway-status-row__route-icon"
            src={iconForRoute(branch)}
          />
        </div>
      )}
      <div className="subway-status-row__status">{status}</div>
      {location && (
        <div className="subway-status-row__location">
          {abbreviate ? location[1] : location[0]}
        </div>
      )}
    </div>
  );
};

const SubwayStatusGreenLineBranchRow = ({ statuses }) => {
  const includesStopClosure = statuses.some(([_, status]) =>
    status.startsWith("Bypassing")
  );
  const modifier = includesStopClosure ? "small" : "normal";

  return (
    <div className="subway-status-row">
      <div className="subway-status-branch-row__route">
        <RoutePill type="text" color="green" text="GL" />
      </div>
      <div className="subway-status-branch-row__groups">
        {statuses.map(([routes, status]) => (
          <div className="subway-status-branch-row__group" key={status}>
            {routes && (
              <div className="subway-status-branch-row__group-routes">
                {routes.map((route) => (
                  <img
                    className="subway-status-branch-row__route-icon"
                    src={iconForRoute(route)}
                    key={route}
                  />
                ))}
              </div>
            )}
            <div
              className={classWithModifier(
                "subway-status-branch-row__group-status",
                modifier
              )}
            >
              {status}
            </div>
          </div>
        ))}
      </div>
    </div>
  );
};

const SubwayStatusGreenLineRow = ({ type, ...data }) => {
  if (type === "trunk") {
    return <SubwayStatusNormalRow {...data} />;
  } else if (type === "branch") {
    return <SubwayStatusGreenLineBranchRow {...data} />;
  }

  return null;
};

const SubwayStatusBody = ({ blue, green, orange, red }) => {
  return (
    <div className="subway-status-body">
      <SubwayStatusNormalRow {...blue} />
      <SubwayStatusNormalRow {...orange} />
      <SubwayStatusNormalRow {...red} />
      <SubwayStatusGreenLineRow {...green} />
    </div>
  );
};

const SubwayStatusFooter = () => {
  return (
    <div className="subway-status-footer">
      <div className="subway-status-footer__link">mbta.com/alerts/subway</div>
    </div>
  );
};

const SubwayStatus = (props) => {
  return (
    <div className="subway-status">
      <SubwayStatusBody {...props} />
      <SubwayStatusFooter />
    </div>
  );
};

export default SubwayStatus;

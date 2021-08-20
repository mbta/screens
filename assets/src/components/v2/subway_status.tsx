import React, { useState, useLayoutEffect, useRef, ComponentType } from "react";

import RoutePill, { Pill } from "Components/v2/departures/route_pill";
import { classWithModifier } from "Util/util";

interface IconProps {
  className: string;
}

const GreenLineBIcon: ComponentType<IconProps> = ({ className }) => (
  <svg
    className={className}
    viewBox="0 0 140 139"
    version="1.1"
    xmlns="http://www.w3.org/2000/svg"
  >
    <rect fill="#00843D" x="0" y="0" width="139" height="139" rx="69.5"></rect>
    <path
      d="M78.7143333,109.77322 C82.2983333,109.77322 85.789,109.32522 89.1863333,108.42922 C92.5836667,107.53322 95.6076667,106.151887 98.2583333,104.28522 C100.909,102.418553 103.018333,100.010553 104.586333,97.0612199 C106.154333,94.1118866 106.938333,90.6212199 106.938333,86.5892199 C106.938333,81.5865533 105.725,77.3118866 103.298333,73.7652199 C100.871667,70.2185533 97.1943333,67.7358866 92.2663333,66.3172199 C95.8503333,64.5998866 98.557,62.3972199 100.386333,59.7092199 C102.215667,57.0212199 103.130333,53.6612199 103.130333,49.6292199 C103.130333,45.8958866 102.514333,42.7598866 101.282333,40.2212199 C100.050333,37.6825533 98.3143333,35.6478866 96.0743333,34.1172199 C93.8343333,32.5865533 91.1463333,31.4852199 88.0103333,30.8132199 C84.8743333,30.1412199 81.4023333,29.8052199 77.5943333,29.8052199 L39.9623333,29.8052199 L39.9623333,109.77322 L78.7143333,109.77322 Z M75.3543333,62.1732199 L57.5463333,62.1732199 L57.5463333,43.4692199 L74.0103333,43.4692199 C75.5783333,43.4692199 77.0903333,43.5998866 78.5463333,43.8612199 C80.0023333,44.1225533 81.2903333,44.5892199 82.4103333,45.2612199 C83.5303333,45.9332199 84.4263333,46.8665533 85.0983333,48.0612199 C85.7703333,49.2558866 86.1063333,50.7865533 86.1063333,52.6532199 C86.1063333,56.0132199 85.0983333,58.4398866 83.0823333,59.9332199 C81.0663333,61.4265533 78.4903333,62.1732199 75.3543333,62.1732199 Z M76.3623333,96.1092199 L57.5463333,96.1092199 L57.5463333,74.1572199 L76.6983333,74.1572199 C80.5063333,74.1572199 83.5676667,75.0345533 85.8823333,76.7892199 C88.197,78.5438866 89.3543333,81.4745533 89.3543333,85.5812199 C89.3543333,87.6718866 88.9996667,89.3892199 88.2903333,90.7332199 C87.581,92.0772199 86.629,93.1412199 85.4343333,93.9252199 C84.2396667,94.7092199 82.8583333,95.2692199 81.2903333,95.6052199 C79.7223333,95.9412199 78.0796667,96.1092199 76.3623333,96.1092199 Z"
      fill="#FFFFFF"
    ></path>
  </svg>
);

const GreenLineCIcon: ComponentType<IconProps> = ({ className }) => (
  <svg
    className={className}
    viewBox="0 0 140 140"
    version="1.1"
    xmlns="http://www.w3.org/2000/svg"
  >
    <rect
      fill="#00843D"
      x="0"
      y="0"
      width="140"
      height="140"
      rx="69.7378218"
    ></rect>
    <path
      d="M71.2391847,111.360653 C76.2026379,111.360653 80.75247,110.608615 84.8886811,109.104538 C89.0248921,107.600461 92.6346763,105.41955 95.7180336,102.561804 C98.8013909,99.7040584 101.283118,96.2446819 103.163213,92.1836747 C105.043309,88.1226675 106.208969,83.5728354 106.660192,78.5341783 L89.513717,78.5341783 C88.8368825,83.9488546 86.9755875,88.3106771 83.9298321,91.619646 C80.8840767,94.9286148 76.6538609,96.5830992 71.2391847,96.5830992 C67.2533813,96.5830992 63.8692086,95.8122599 61.0866667,94.2705812 C58.3041247,92.7289026 56.0480096,90.679598 54.3183213,88.1226675 C52.5886331,85.5657371 51.3289688,82.6891903 50.5393285,79.4930273 C49.7496882,76.2968642 49.3548681,73.0066963 49.3548681,69.6225237 C49.3548681,66.0879433 49.7496882,62.6661687 50.5393285,59.3571999 C51.3289688,56.0482311 52.5886331,53.0964805 54.3183213,50.5019481 C56.0480096,47.9074158 58.3041247,45.8393102 61.0866667,44.2976316 C63.8692086,42.7559529 67.2533813,41.9851136 71.2391847,41.9851136 C73.4200959,41.9851136 75.5070024,42.3423318 77.4999041,43.0567683 C79.4928058,43.7712047 81.2788969,44.7676556 82.8581775,46.0461208 C84.437458,47.324586 85.7535252,48.8098618 86.8063789,50.5019481 C87.8592326,52.1940345 88.5360671,54.0553294 88.8368825,56.085833 L105.983357,56.085833 C105.45693,51.4231951 104.178465,47.2869841 102.147962,43.6771999 C100.117458,40.0674158 97.5417266,37.0404613 94.4207674,34.5963366 C91.2998082,32.1522119 87.7652278,30.2909169 83.8170264,29.0124517 C79.8688249,27.7339865 75.676211,27.0947539 71.2391847,27.0947539 C65.07247,27.0947539 59.5261871,28.1852095 54.6003357,30.3661208 C49.6744844,32.5470321 45.5194724,35.5551855 42.1352998,39.3905812 C38.7511271,43.2259769 36.1565947,47.7194062 34.3517026,52.870869 C32.5468106,58.0223318 31.6443645,63.6062167 31.6443645,69.6225237 C31.6443645,75.4884229 32.5468106,80.9595021 34.3517026,86.0357611 C36.1565947,91.1120201 38.7511271,95.5302455 42.1352998,99.2904373 C45.5194724,103.050629 49.6744844,106.00238 54.6003357,108.145689 C59.5261871,110.288998 65.07247,111.360653 71.2391847,111.360653 Z"
      fill="#FFFFFF"
    ></path>
  </svg>
);

const GreenLineDIcon: ComponentType<IconProps> = ({ className }) => (
  <svg
    className={className}
    viewBox="0 0 139 139"
    version="1.1"
    xmlns="http://www.w3.org/2000/svg"
  >
    <rect fill="#00843D" x="0" y="0" width="139" height="139" rx="69.5"></rect>
    <path
      d="M74.3863333,108.77322 C80.509,108.77322 85.829,107.746553 90.3463333,105.69322 C94.8636667,103.639887 98.6343333,100.82122 101.658333,97.2372199 C104.682333,93.6532199 106.941,89.3972199 108.434333,84.4692199 C109.927667,79.5412199 110.674333,74.1652199 110.674333,68.3412199 C110.674333,61.6958866 109.759667,55.9092199 107.930333,50.9812199 C106.101,46.0532199 103.562333,41.9465533 100.314333,38.6612199 C97.0663333,35.3758866 93.221,32.9118866 88.7783333,31.2692199 C84.3356667,29.6265533 79.5383333,28.8052199 74.3863333,28.8052199 L39.8903333,28.8052199 L39.8903333,108.77322 L74.3863333,108.77322 Z M73.1543333,93.9892199 L57.4743333,93.9892199 L57.4743333,43.5892199 L70.0183333,43.5892199 C74.349,43.5892199 77.989,44.2052199 80.9383333,45.4372199 C83.8876667,46.6692199 86.2583333,48.4425533 88.0503333,50.7572199 C89.8423333,53.0718866 91.1303333,55.8532199 91.9143333,59.1012199 C92.6983333,62.3492199 93.0903333,65.9892199 93.0903333,70.0212199 C93.0903333,74.4265533 92.5303333,78.1598866 91.4103333,81.2212199 C90.2903333,84.2825533 88.797,86.7652199 86.9303333,88.6692199 C85.0636667,90.5732199 82.9356667,91.9358866 80.5463333,92.7572199 C78.157,93.5785533 75.693,93.9892199 73.1543333,93.9892199 Z"
      fill="#FFFFFF"
    ></path>
  </svg>
);

const GreenLineEIcon: ComponentType<IconProps> = ({ className }) => (
  <svg
    className={className}
    viewBox="0 0 140 140"
    version="1.1"
    xmlns="http://www.w3.org/2000/svg"
  >
    <rect
      fill="#00843D"
      x="0"
      y="0"
      width="140"
      height="140"
      rx="69.7378218"
    ></rect>
    <polygon
      fill="#FFFFFF"
      points="101.406272 110.562955 101.406272 95.728366 58.1387194 95.728366 58.1387194 76.0612968 97.0233248 76.0612968 97.0233248 62.3505401 58.1387194 62.3505401 58.1387194 45.1559024 100.507206 45.1559024 100.507206 30.3213131 40.4945488 30.3213131 40.4945488 110.562955"
    ></polygon>
  </svg>
);

type IconRouteId = "Green-B" | "Green-C" | "Green-D" | "Green-E";

interface IconForRouteProps {
  className: string;
  routeId: IconRouteId;
}

const routeIconMapping: Record<IconRouteId, ComponentType<IconProps>> = {
  "Green-B": GreenLineBIcon,
  "Green-C": GreenLineCIcon,
  "Green-D": GreenLineDIcon,
  "Green-E": GreenLineEIcon,
};

const IconForRoute: ComponentType<IconForRouteProps> = ({
  className,
  routeId,
}) => {
  const IconComponent = routeIconMapping[routeId];

  return <IconComponent className={className} />;
};

interface SubwayStatusNormalRowProps {
  route: Pill;
  status: string;
  location?: { full: string; abbrev: string };
  branch?: IconRouteId;
}

const SubwayStatusNormalRow: ComponentType<SubwayStatusNormalRowProps> = ({
  route,
  status,
  location,
  branch,
}) => {
  const [abbreviate, setAbbreviate] = useState(false);
  const [dropTimes, setDropTimes] = useState(false);
  const ref = useRef<HTMLElement>(null);

  useLayoutEffect(() => {
    if (ref.current) {
      if (ref.current.clientHeight > 122) {
        if (abbreviate && !dropTimes) {
          setDropTimes(true);
        } else {
          setAbbreviate(true);
        }
      }
    }
  });

  if (abbreviate) {
    status = status.replace(" minutes", "m");
  }

  if (dropTimes && status.startsWith("Delays")) {
    status = "Delays";
  }

  return (
    <div className="subway-status-row" ref={ref}>
      <div className="subway-status-row__route">
        <RoutePill {...route} />
      </div>
      {branch && (
        <div className="subway-status-row__branch">
          <IconForRoute
            className="subway-status-row__route-icon"
            routeId={branch}
          />
        </div>
      )}
      <div className="subway-status-row__status">{status}</div>
      {location && (
        <div className="subway-status-row__location">
          {abbreviate ? location.abbrev : location.full}
        </div>
      )}
    </div>
  );
};

interface GlMultipleProps {
  statuses: [IconRouteId[], string][];
}

const SubwayStatusGreenLineMultipleAlertsRow: ComponentType<GlMultipleProps> = ({
  statuses,
}) => {
  const includesStopClosure = statuses.some(([_, status]) =>
    status.toLowerCase().startsWith("bypassing")
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
            <div className="subway-status-branch-row__group-routes">
              {routes.map((route) => (
                <IconForRoute
                  className="subway-status-branch-row__route-icon"
                  routeId={route}
                  key={route}
                />
              ))}
            </div>
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

type GlRowProps =
  | (SubwayStatusNormalRowProps & { type: "single" })
  | (GlMultipleProps & { type: "multiple" });

const SubwayStatusGreenLineRow: ComponentType<GlRowProps> = (props) => {
  if (props.type === "single") {
    return <SubwayStatusNormalRow {...props} />;
  } else if (props.type === "multiple") {
    return <SubwayStatusGreenLineMultipleAlertsRow {...props} />;
  }

  return null;
};

interface SubwayStatusProps {
  blue: SubwayStatusNormalRowProps;
  green: GlRowProps;
  orange: SubwayStatusNormalRowProps;
  red: SubwayStatusNormalRowProps;
}

const SubwayStatusBody: ComponentType<SubwayStatusProps> = ({
  blue,
  green,
  orange,
  red,
}) => {
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

const SubwayStatus: ComponentType<SubwayStatusProps> = (props) => {
  return (
    <div className="subway-status">
      <SubwayStatusBody {...props} />
      <SubwayStatusFooter />
    </div>
  );
};

export default SubwayStatus;

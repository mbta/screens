import React, { useState, useLayoutEffect, useRef } from "react";
import { classWithModifier, imagePath } from "Util/util";

import RoutePill, {
  Pill,
  routePillKey,
} from "Components/v2/departures/route_pill";

interface Props {
  route_pills: [] | [Pill] | [Pill, Pill];
  icon: AlertIcon;
  header: string;
  body: string;
  url: string;
}

type AlertIcon = "bus" | "x" | "warning" | "snowflake";

const Alert = ({
  route_pills: routePills,
  icon,
  header,
  body,
  url,
}: Props): JSX.Element => {
  return (
    <div className="alert-widget">
      <AlertCard>
        <div className="alert-widget__content">
          <div className="alert-widget__content__route-pills">
            {routePills.map((pill) => (
              <RoutePill {...pill} key={routePillKey(pill)} />
            ))}
          </div>
          <div className="alert-widget__content__icon">
            <img className="alert-widget__icon-image" src={imagePath(filenameForIcon(icon))} />
          </div>
          <div className="alert-widget__content__header-text">{header}</div>
          <BodyTextSizer>{body}</BodyTextSizer>
          <div className="alert-widget__content__cta">
            <div className="alert-widget__content__cta__url">{url}</div>
          </div>
        </div>
      </AlertCard>
    </div>
  );
};

interface AlertCardProps {
  children: React.ReactNode;
}

const AlertCard = ({ children }: AlertCardProps): JSX.Element => (
  <svg
    className="alert-widget__card"
    height="620"
    viewBox="0 0 520 620"
    width="520"
    xmlns="http://www.w3.org/2000/svg"
    xmlnsXlink="http://www.w3.org/1999/xlink"
  >
    <defs>
      <path
        id="a"
        d="m154.627417 10h329.372583c8.836556 0 16 7.163444 16 16v548c0 8.836556-7.163444 16-16 16h-448c-8.836556 0-16-7.163444-16-16v-429.372583c0-4.243464 1.6857094-8.313126 4.6862915-11.313709l118.6274165-118.6274165c3.000583-3.0005821 7.070245-4.6862915 11.313709-4.6862915z"
      />
      <filter id="b" height="112.1%" width="114.6%" x="-7.3%" y="-4.3%">
        <feOffset dx="0" dy="10" in="SourceAlpha" result="shadowOffsetOuter1" />
        <feGaussianBlur
          in="shadowOffsetOuter1"
          result="shadowBlurOuter1"
          stdDeviation="10"
        />
        <feColorMatrix
          in="shadowBlurOuter1"
          type="matrix"
          values="0 0 0 0 0.09   0 0 0 0 0.122   0 0 0 0 0.15  0 0 0 0.25 0"
        />
      </filter>
    </defs>
    <g fill="none" fillRule="evenodd" transform="matrix(-1 0 0 1 520 0)">
      <use fill="#000" filter="url(#b)" xlinkHref="#a" />
      <use fill="#e6e4e1" fillRule="evenodd" xlinkHref="#a" />
    </g>
    <foreignObject x="20" y="10" width="480" height="580">
      {children}
    </foreignObject>
  </svg>
);

const filenameForIcon = (icon: AlertIcon) =>
  `alert-widget-icon-${icon}--color.svg`;

const BodyTextSizer = ({ children }: { children: string }): JSX.Element => {
  const [isSmall, setSmall] = useState(false);
  const ref = useRef(null);

  useLayoutEffect(() => {
    if (ref.current && !isSmall && ref.current.clientHeight > 280) {
      setSmall(true);
    }
  });

  return (
    <div
      className={classWithModifier(
        "alert-widget__content__body-text",
        isSmall ? "small" : "regular"
      )}
      ref={ref}
    >
      {children}
    </div>
  );
};

export default Alert;

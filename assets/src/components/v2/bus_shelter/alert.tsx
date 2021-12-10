import React, { ComponentType } from "react";

import BaseAlert, { Props, AlertCardProps, AlertIcon } from "Components/v2/alert";

const FlexZoneAlert: ComponentType<Props> = (props) => {
  return (
    <BaseAlert
      alertProps={props}
      classModifier="flex-zone"
      CardComponent={FlexZoneAlertCard}
      bodyTextMaxHeight={280}
      iconFilenameFn={filenameForFlexZoneIcon}
    />
  );
};

const FullBodyAlert: ComponentType<Props> = (props) => {
  return (
    <BaseAlert
      alertProps={props}
      classModifier="full-body"
      CardComponent={FullBodyAlertCard}
      bodyTextMaxHeight={744}
      iconFilenameFn={filenameForFullBodyIcon}
    />
  );
};

const FlexZoneAlertCard: ComponentType<AlertCardProps> = ({ children }) => (
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

const FullBodyAlertCard: ComponentType<AlertCardProps> = ({ children }) => (
  <svg
    className="alert-widget__card"
    height="1648"
    viewBox="0 0 1080 1648"
    width="1080"
    xmlns="http://www.w3.org/2000/svg"
    xmlnsXlink="http://www.w3.org/1999/xlink"
  >
    <defs>
      <path
        id="a"
        d="m205.254834 0h762.745166c17.673112 0 32 14.326888 32 32v1504c0 17.67311-14.326888 32-32 32h-936c-17.673112 0-32-14.32689-32-32v-1330.745166c0-8.486928 3.37141889-16.626253 9.372583-22.627417l173.254834-173.254834c6.001164-6.00116411 14.140489-9.372583 22.627417-9.372583z"
      />
      <filter id="b" height="108.3%" width="113%" x="-6.5%" y="-3.5%">
        <feOffset dx="0" dy="10" in="SourceAlpha" result="shadowOffsetOuter1" />
        <feGaussianBlur
          in="shadowOffsetOuter1"
          result="shadowBlurOuter1"
          stdDeviation="20"
        />
        <feColorMatrix
          in="shadowBlurOuter1"
          type="matrix"
          values="0 0 0 0 0.09   0 0 0 0 0.122   0 0 0 0 0.15  0 0 0 0.5 0"
        />
      </filter>
    </defs>
    <g fill="none" fillRule="evenodd" transform="matrix(-1 0 0 1 1040 30)">
      <use fill="#000" filter="url(#b)" xlinkHref="#a" />
      <use fill="#171f26" fillRule="evenodd" xlinkHref="#a" />
    </g>
    <foreignObject x="40" y="30" width="1000" height="1568">
      {children}
    </foreignObject>
  </svg>
);

const filenameForFlexZoneIcon = (icon: AlertIcon) =>
  `alert-widget-icon-${icon}--color.svg`;

const filenameForFullBodyIcon = (icon: AlertIcon) => {
  switch (icon) {
    case "bus":
      return "bus-negative-yellow.svg";
    case "x":
      return "no-service-yellow.svg";
    case "warning":
      return "alert-yellow.svg";
    default:
      return "alert-yellow.svg";
  }
};

export { FlexZoneAlert, FullBodyAlert };

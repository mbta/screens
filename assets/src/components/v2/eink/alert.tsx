import React, { ComponentType } from "react";

import BaseAlert, { Props, AlertCardProps, AlertIcon } from "Components/v2/alert";
import LinkArrow from "Components/v2/bundled_svg/link_arrow";

// E-Ink alert widget always displays the same URL, even when a different one
// is supplied in the alert data. This is because we can't dynamically resize
// the right-pointing arrow that shares the line with the URL.
const propsWithStaticUrl = (props: Props): Props => ({ ...props, url: "mbta.com/alerts" });

const MediumFlexAlert: ComponentType<Props> = (props) => {
  return (
    <BaseAlert
      alertProps={propsWithStaticUrl(props)}
      classModifier="flex-zone"
      CardComponent={MediumFlexAlertCard}
      LinkArrowComponent={() => <LinkArrow width={473} colorHex="#ffffff" />}
      bodyTextMaxHeight={528}
      iconFilenameFn={filenameForMediumFlexIcon}
    />
  );
};

const FullBodyTopScreenAlert: ComponentType<Props> = (props) => {
  return (
    <BaseAlert
      alertProps={propsWithStaticUrl(props)}
      classModifier="full-body"
      CardComponent={FullBodyTopScreenAlertCard}
      LinkArrowComponent={() => <LinkArrow width={422} colorHex="#000000" />}
      bodyTextMaxHeight={576}
      iconFilenameFn={filenameForFullBodyTopScreenIcon}
    />
  );
};

const MediumFlexAlertCard: ComponentType<AlertCardProps> = ({ children }) => (
  <svg width="1136px" height="1080px" viewBox="0 0 1136 1080" version="1.1" xmlns="http://www.w3.org/2000/svg" xmlnsXlink="http://www.w3.org/1999/xlink">
    <title>alert widget-standard</title>
    <g id="Flex-Zone-widgets" stroke="none" strokeWidth="1" fill="none" fillRule="evenodd">
      <g id="E-Ink/Flex-Zone/M-Alert-small-type" fill="#000000">
        <path d="M269.254834,0 L1104,0 C1121.67311,-6.79921168e-15 1136,14.326888 1136,32 L1136,1048 C1136,1065.67311 1121.67311,1080 1104,1080 L32,1080 C14.326888,1080 -9.0733037e-13,1065.67311 -9.09494702e-13,1048 L-9.09494702e-13,269.254834 C-9.29162576e-13,260.767906 3.37141889,252.628581 9.372583,246.627417 L246.627417,9.372583 C252.628581,3.37141889 260.767906,1.55902332e-15 269.254834,0 Z" id="alert-widget-standard" transform="translate(568.000000, 540.000000) scale(-1, 1) translate(-568.000000, -540.000000) "></path>
      </g>
    </g>
    <foreignObject width="1136" height="1080">
      {children}
    </foreignObject>
  </svg>
);

const FullBodyTopScreenAlertCard: ComponentType<AlertCardProps> = ({ children }) => (
  <svg width="1136px" height="1280px" viewBox="0 0 1136 1280" version="1.1" xmlns="http://www.w3.org/2000/svg" xmlnsXlink="http://www.w3.org/1999/xlink">
    <title>alert widget-takeover</title>
    <g id="Flex-Zone-widgets" stroke="none" strokeWidth="1" fill="none" fillRule="evenodd">
      <g id="E-Ink/Alert-Full/GL" transform="translate(-32.000000, -288.000000)" fill="#FFFFFF">
        <g id="Group" transform="translate(32.000000, 288.000000)">
          <path d="M205.254834,0 L1104,0 C1121.67311,-3.24649801e-15 1136,14.326888 1136,32 L1136,1248.00155 C1136,1265.67466 1121.67311,1280.00155 1104,1280.00155 L32,1280.00155 C14.326888,1280.00155 2.164332e-15,1265.67466 0,1248.00155 L0,205.254834 C3.49202666e-14,196.767906 3.37141889,188.628581 9.372583,182.627417 L182.627417,9.372583 C188.628581,3.37141889 196.767906,-1.97572588e-14 205.254834,0 Z" id="alert-widget-takeover" transform="translate(568.000000, 640.000774) scale(-1, 1) translate(-568.000000, -640.000774) "></path>
        </g>
      </g>
    </g>
    <foreignObject width="1136" height="1280">
      {children}
    </foreignObject>
  </svg>
);

const filenameForMediumFlexIcon = (icon: AlertIcon) =>
  `alert-widget-icon-${icon}--eink.svg`;

const filenameForFullBodyTopScreenIcon = (icon: AlertIcon) => {
  switch (icon) {
    case "bus":
      return "bus-negative-black.svg";
    case "x":
      return "no-service-black.svg";
    case "warning":
      return "alert-black.svg";
    case "snowflake":
      return "alert-widget-icon-snowflake--eink.svg"
    default:
      return "alert-black.svg";
  }
};

export { MediumFlexAlert, FullBodyTopScreenAlert };

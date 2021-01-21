import React from "react";
import _ from "lodash";

import { classWithModifier, imagePath } from "Util/util";

const alertValues = _.mapValues({
  delay: { svgPath: "solari-delay-white.svg", text: "delays" },
  snow_route: { svgPath: "solari-snowflake.svg", text: "snow route" },
  last_trip: { svgPath: "solari-moon.svg", text: "last trip" },
}, ({ svgPath, ...rest }) => ({ ...rest, svgPath: imagePath(svgPath) }));

interface InlineAlertBadgeProps {
  alert: "delay" | "snow_route" | "last_trip";
}

const InlineAlertBadge = ({ alert }: InlineAlertBadgeProps): JSX.Element => {
  const { svgPath, text } = alertValues[alert];

  const withModifier = (className: string) =>
    classWithModifier(className, alert);

  return (
    <div className={withModifier("inline-alert-badge")}>
      <div className={withModifier("inline-alert-badge__icon-container")}>
        <img
          className={withModifier("inline-alert-badge__icon-image")}
          src={svgPath}
        />
      </div>
      <div className={withModifier("inline-alert-badge__text")}>{text}</div>
    </div>
  );
};

export default InlineAlertBadge;

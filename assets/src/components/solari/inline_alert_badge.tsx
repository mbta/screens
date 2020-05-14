import React from "react";

const alertValues = {
  delay: { svgPath: "/images/solari-delay-white.svg", text: "delays" },
  snow_route: { svgPath: "/images/solari-snowflake.svg", text: "snow route" },
  last_trip: { svgPath: "/images/solari-moon.svg", text: "last trip" },
};

interface InlineAlertBadgeProps {
  alert: "delay" | "snow_route" | "last_trip";
}

const InlineAlertBadge = ({ alert }: InlineAlertBadgeProps): JSX.Element => {
  const { svgPath, text } = alertValues[alert];

  const withClassModifier = (className: string) =>
    `${className} ${className}--${alert}`;

  return (
    <div className={withClassModifier("inline-alert-badge")}>
      <div className={withClassModifier("inline-alert-badge__icon-container")}>
        <img
          className={withClassModifier("inline-alert-badge__icon-image")}
          src={svgPath}
        />
      </div>
      <div className={withClassModifier("inline-alert-badge__text")}>
        {text}
      </div>
    </div>
  );
};

export default InlineAlertBadge;

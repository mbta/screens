import React, { ComponentType } from "react";

interface Props {
  minutes: number;
  fgColor: string;
  bgColor: string;
}

/**
 * **TO USE**
 * 1. Import `v2/clock_icon` in the CSS of the relevant app(s), e.g. pre_fare_v2.scss.
 * 2. Render this component inside of a container element, so that you can apply dimensions.
 *    ```
 *    <div className=".my-widget__clock-icon-container"><ClockIcon {...clockProps} /></div>
 *    ```
 * 3. In the CSS for the widget where this component is used, specify the containing element's width and height:
 *    ```
 *    .my-widget__clock-icon-container {
*       width: 56px;
*       height: 56px;
 *    }
 *    ```
 *    The icon will scale to fill its container.
 *
 * This draws a clock icon with the given number of `minutes` filled in with `fgColor`
 * and the rest filled with `bgColor`.
 *
 * `minutes` must be >= 0 and <= 60.
 */
const ClockIcon: ComponentType<Props> = ({ minutes, fgColor, bgColor }) => {
  if (minutes < 0 || minutes > 60 || isNaN(minutes)) {
    throw new Error(`minutes must be between 0 and 60 inclusive, got ${minutes}`);
  }

  const deg = Math.round(minutes * 360 / 60);

  const radialGradient = `radial-gradient(closest-side, ${bgColor} 0, ${bgColor} calc(100% * (22/28)), ${fgColor} calc(100% * (22/28)), ${fgColor} 100%, transparent)`;
  const conicGradient = `conic-gradient(${fgColor} 0, ${fgColor} ${deg}deg, ${bgColor} ${deg}deg, ${bgColor} 100%)`;

  return (
    <div className="ClockIcon">
      <div className="ClockIcon-frame" style={{ background: radialGradient }}>
        <div className="ClockIcon-face" style={{ background: conicGradient }} />
      </div>
    </div>
  );
};

export default ClockIcon;

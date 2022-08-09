import React, { ComponentType } from "react";

interface Props {
  className?: string;
  colorHex: string;
}

const LoadingHourglass: ComponentType<Props> = ({ className, colorHex }) => (
  <svg
    className={className}
    width="128px"
    height="128px"
    viewBox="0 0 128 128"
    version="1.1"
    xmlns="http://www.w3.org/2000/svg"
    xmlnsXlink="http://www.w3.org/1999/xlink"
  >
    <title>Icon/Live data-None</title>
    <g
      id="Icon/Live-data-None"
      stroke="none"
      strokeWidth="1"
      fill="none"
      fillRule="evenodd"
    >
      <path
        d="M64,90 C70.627417,90 76,95.372583 76,102 C76,108.627417 70.627417,114 64,114 C57.372583,114 52,108.627417 52,102 C52,95.372583 57.372583,90 64,90 Z M22.6690541,17.0205701 L22.8284271,17.1715729 L110.828427,105.171573 C112.390524,106.73367 112.390524,109.26633 110.828427,110.828427 C109.3184,112.338454 106.901436,112.388789 105.330946,110.97943 L105.171573,110.828427 L70.0197013,75.6759623 C61.2705147,73.6839522 51.7215634,76.0946704 44.9081169,82.9081169 C41.002874,86.8133598 34.6712242,86.8133598 30.7659813,82.9081169 C26.8607384,79.002874 26.8607384,72.6712242 30.7659813,68.7659813 C36.6363156,62.8956469 43.6731784,58.9028118 51.130392,56.7874759 L39.4111714,45.0663459 C32.4200552,48.083283 25.8711316,52.4476276 20.1593796,58.1593796 C16.2541366,62.0646225 9.92248686,62.0646225 6.01724394,58.1593796 C2.11200102,54.2541366 2.11200102,47.9224869 6.01724394,44.0172439 C11.629888,38.4045999 17.8537396,33.7756794 24.474547,30.1304826 L17.1715729,22.8284271 C15.6094757,21.26633 15.6094757,18.73367 17.1715729,17.1715729 C18.6816001,15.6615456 21.0985644,15.6112114 22.6690541,17.0205701 Z M97.2340187,68.7659813 C101.139262,72.6712242 101.139262,79.002874 97.2340187,82.9081169 C97.1217026,83.020433 97.0073795,83.1295188 96.8911649,83.2353744 L68.9141857,55.2560549 C79.2562637,56.3369902 89.3083364,60.8402989 97.2340187,68.7659813 Z M121.982756,44.0172439 C125.887999,47.9224869 125.887999,54.2541366 121.982756,58.1593796 C118.077513,62.0646225 111.745863,62.0646225 107.84062,58.1593796 C93.2851002,43.6038593 73.2929309,37.7984936 54.4006731,40.7432824 L37.9015791,24.2450241 C66.4610976,14.6835304 99.2397825,21.2742704 121.982756,44.0172439 Z"
        id="No-signal"
        fill={colorHex}
      ></path>
    </g>
  </svg>
);

export default LoadingHourglass;

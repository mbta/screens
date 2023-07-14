import React, { ComponentType } from "react";

interface Props {
  className?: string;
  colorHex: string;
}

const LiveData: ComponentType<Props> = ({ className, colorHex }) => (
  <svg
    className={className}
    width="32px"
    height="32px"
    viewBox="0 0 32 32"
    version="1.1"
    xmlns="http://www.w3.org/2000/svg"
    xmlnsXlink="http://www.w3.org/1999/xlink"
  >
    <title>Icon/Live data-Small</title>
    <g
      id="Icon/Live-data-Small"
      stroke="none"
      strokeWidth="1"
      fill="none"
      fillRule="evenodd"
    >
      <path
        d="M26,23 C27.6568542,23 29,24.3431458 29,26 C29,27.6568542 27.6568542,29 26,29 C24.3431458,29 23,27.6568542 23,26 C23,24.3431458 24.3431458,23 26,23 Z M26,13 C27.1045695,13 28,13.8954305 28,15 C28,16.1045695 27.1045695,17 26,17 C21.0294373,17 17,21.0294373 17,26 C17,27.1045695 16.1045695,28 15,28 C13.8954305,28 13,27.1045695 13,26 C13,18.8202983 18.8202983,13 26,13 Z M26,3 C27.1045695,3 28,3.8954305 28,5 C28,6.1045695 27.1045695,7 26,7 C15.5065898,7 7,15.5065898 7,26 C7,27.1045695 6.1045695,28 5,28 C3.8954305,28 3,27.1045695 3,26 C3,13.2974508 13.2974508,3 26,3 Z"
        id="Signal"
        fill={colorHex}
      ></path>
    </g>
  </svg>
);

export default LiveData;

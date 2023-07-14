import React, { ComponentType } from "react";

interface Props {
  className?: string;
  colorHex: string;
}

const OvernightMoon: ComponentType<Props> = ({ className, colorHex }) => (
  <svg
    className={className}
    width="128px"
    height="128px"
    viewBox="0 0 128 128"
    version="1.1"
    xmlns="http://www.w3.org/2000/svg"
    xmlnsXlink="http://www.w3.org/1999/xlink"
  >
    <title>Icon/Last trip</title>
    <g
      id="Icon/Last-trip"
      stroke="none"
      strokeWidth="1"
      fill="none"
      fillRule="evenodd"
    >
      <path
        d="M32,32 C32,67.346224 60.653776,96 96,96 C105.390884,96 114.309367,93.9774056 122.343587,90.3440762 C112.301966,112.549262 89.9553395,128 64,128 C28.653776,128 0,99.346224 0,64 C0,38.0446605 15.4507384,15.6980342 37.6564128,5.65592382 C34.0225219,13.6909529 32,22.6092838 32,32 Z"
        id="Moon"
        fill={colorHex}
      ></path>
    </g>
  </svg>
);

export default OvernightMoon;

import React, { ComponentType } from "react";

interface Props {
  className?: string;
  colorHex: string;
}

const TLogo: ComponentType<Props> = ({ className, colorHex }) => (
  <svg
    className={className}
    width="1000px"
    height="1000px"
    viewBox="0 0 1000 1000"
    version="1.1"
    xmlns="http://www.w3.org/2000/svg"
    xmlnsXlink="http://www.w3.org/1999/xlink"
  >
    <title>Logo/T KO</title>
    <g
      id="Logo/T-KO"
      stroke="none"
      strokeWidth="1"
      fill="none"
      fillRule="evenodd"
    >
      <path
        d="M500,0 C776.142375,0 1000,223.857625 1000,500 C1000,776.142375 776.142375,1000 500,1000 C223.857625,1000 0,776.142375 0,500 C0,223.857625 223.857625,0 500,0 Z M500,44 C248.158154,44 44,248.158154 44,500 C44,751.841846 248.158154,956 500,956 C751.841846,956 956,751.841846 956,500 C956,248.158154 751.841846,44 500,44 Z M816,277 L816,436 L579.5,436 L579.5,825 L420.5,825 L420.5,436 L184,436 L184,277 L816,277 Z"
        id="Color"
        fill={colorHex}
      ></path>
    </g>
  </svg>
);

export default TLogo;

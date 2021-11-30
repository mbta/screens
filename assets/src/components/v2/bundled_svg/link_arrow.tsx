import React, { ComponentType } from "react";

interface Props {
  width: number;
  colorHex: string;
}

/**
 * A 40px high right-pointing arrow. You specify its width and color.
 */
const LinkArrow: ComponentType<Props> = ({ width, colorHex }) => {
  const height = 40;
  const stroke = 8;
  const headWidth = 40;

  const d = [
    "M",
    stroke / 2,
    height / 2,
    "L",
    width - headWidth,
    height / 2,
    "L",
    width - headWidth,
    stroke / 2,
    "L",
    width - stroke / 2,
    height / 2,
    "L",
    width - headWidth,
    height - stroke / 2,
    "L",
    width - headWidth,
    height / 2,
    "Z",
  ].join(" ");

  return (
    <svg
      xmlns="http://www.w3.org/2000/svg"
      viewBox={`0 0 ${width} ${height}`}
      width={`${width}px`}
      height={`${height}px`}
      version="1.1"
    >
      <path
        stroke={colorHex}
        strokeWidth={stroke}
        strokeLinecap="round"
        strokeLinejoin="round"
        fill={colorHex}
        d={d}
      />
    </svg>
  );
};

export default LinkArrow;

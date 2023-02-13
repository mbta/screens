import React from "react";

import { Icon } from "../normal_header";
import FreeText, { FreeTextType } from "./dup_free_text";
import NormalHeader from "./normal_header";

const LinkArrow = ({ width, color }: any) => {
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
        stroke={color}
        strokeWidth={stroke}
        strokeLinecap="round"
        strokeLinejoin="round"
        fill={color}
        d={d}
      />
    </svg>
  );
};

interface TakeoverAlertProps {
  text: FreeTextType,
  remedy: FreeTextType,
  header: {
    icon: Icon,
    text: string,
    color: string
  }
}

const TakeoverAlert = (alert: TakeoverAlertProps) => {
  const {text, remedy, header} = alert
  
  return (
    <>
      <NormalHeader
        icon={header.icon}
        text={header.text}
        color={header.color}
        accentPattern
      />
      <div className="full-screen-alert__body">
        <div className="full-screen-alert-text">
          <FreeText lines={[text, remedy]} />
        </div>
        <div className="full-screen-alert__link">
          <div className="full-screen-alert__link-arrow">
            <LinkArrow width="628" color="#64696e" />
          </div>
          <div className="full-screen-alert__link-text">mbta.com/alerts</div>
        </div>
      </div>
      </>
  );
};

export default TakeoverAlert;

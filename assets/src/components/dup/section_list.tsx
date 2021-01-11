import React from "react";

import Section, { HeadwaySection } from "Components/dup/section";
import { getKey, FreeTextElement } from "Components/dup/free_text";
import { classWithModifier } from "Util/util";

const LinkArrow = ({ width }) => {
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
        stroke="#a2a3a3"
        strokeWidth={stroke}
        strokeLinecap="round"
        strokeLinejoin="round"
        fill="#a2a3a3"
        d={d}
      />
    </svg>
  );
};

const HeadwaySectionList = ({ section: { pill, headway } }): JSX.Element => {
  const pillToLineName = {
    blue: "BLUE LINE",
    green: "GREEN LINE",
    orange: "ORANGE LINE",
    red: "RED LINE",
    mattapan: "MATTAPAN LINE",
  };

  const [lo, hi] = headway;
  const lineText = { color: pill, text: pillToLineName[pill] };
  const headwayText = [
    "every",
    { format: "bold", text: `${lo}-${hi}` },
    "minutes",
  ];

  return (
    <div className={classWithModifier("section-list", "headway")}>
      <div className="headway-section-list">
        <div className="headway-section-list__icon-container">
          <img
            className="headway-section-list__icon-image"
            src="/images/subway-negative-black.svg"
          />
        </div>
        <div className="headway-section-list__message">
          <div>
            <FreeTextElement elt={lineText} />
          </div>
          <div>
            {headwayText.map((elt) => (
              <FreeTextElement elt={elt} key={getKey(elt)} />
            ))}
          </div>
        </div>
        <div className="headway-section-list__link">
          <div className="headway-section-list__link-arrow">
            <LinkArrow width="375" />
          </div>
          <div className="headway-section-list__link-text">
            mbta.com/schedules
          </div>
        </div>
      </div>
    </div>
  );
};

const SectionList = ({ sections, currentTimeString }): JSX.Element => {
  if (sections.length === 1 && sections[0].headway) {
    return <HeadwaySectionList section={sections[0]} />;
  }

  return (
    <div className="section-list">
      {sections.map(({ departures, pill, headway }) => {
        if (headway) {
          return <HeadwaySection headway={headway} pill={pill} key={pill} />;
        } else {
          return (
            <Section
              departures={departures}
              currentTimeString={currentTimeString}
              key={pill}
            />
          );
        }
      })}
    </div>
  );
};

export default SectionList;

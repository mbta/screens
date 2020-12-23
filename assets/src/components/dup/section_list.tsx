import React from "react";

import Section, { HeadwaySection } from "Components/dup/section";
import { getKey, FreeTextElement } from "Components/dup/free_text";

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
    <div className="section-list">
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
        <div className="headway-section-list__link">mbta.com/schedules</div>
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

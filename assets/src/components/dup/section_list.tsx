import React from "react";

import Section from "Components/dup/section";

const SectionList = ({ sections, currentTimeString }): JSX.Element => {
  return (
    <div className="section-list">
      {sections.map(({ departures, pill }) => (
        <Section
          departures={departures}
          currentTimeString={currentTimeString}
          key={pill}
        />
      ))}
    </div>
  );
};

export default SectionList;

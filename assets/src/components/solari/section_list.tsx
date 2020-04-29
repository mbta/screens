import React from "react";

import Section from "Components/solari/section";

const SectionList = ({ sections, currentTimeString }): JSX.Element => {
  return (
    <div className="section-list">
      {sections.map((section) => (
        <Section
          {...section}
          currentTimeString={currentTimeString}
          key={section.name}
        />
      ))}
    </div>
  );
};

export default SectionList;

import React from "react";

import Section from "Components/dup/section";

const SectionList = ({ sections, currentTimeString }): JSX.Element => {
  return (
    <div className="section-list">
      <Section departures={sections[0]} currentTimeString={currentTimeString} />
    </div>
  );
};

export default SectionList;

import React from "react";

import SectionListSizer from "Components/solari/section_list_sizer";
import SectionList from "Components/solari/section_list";

interface Props {
  sections: object[];
  sectionHeaders: string;
  currentTimeString: string;
  overhead: boolean;
}

const SectionListContainer = ({
  sections,
  sectionHeaders,
  currentTimeString,
  overhead,
}: Props): JSX.Element => {
  const [sectionSizes, setSectionSizes] = React.useState([] as number[]);

  return (
    <div className="section-list-container">
      {sectionSizes.length > 0 && (
        <SectionList
          sections={sections}
          sectionSizes={sectionSizes}
          sectionHeaders={sectionHeaders}
          currentTimeString={currentTimeString}
          overhead={overhead}
        />
      )}
      <SectionListSizer
        sections={sections}
        sectionHeaders={sectionHeaders}
        currentTimeString={currentTimeString}
        overhead={overhead}
        onDoneSizing={setSectionSizes}
      />
    </div>
  );
};

export default SectionListContainer;

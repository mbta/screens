import React from "react";

import { PagedSection, Section } from "Components/solari/section";
import { classWithModifier } from "Util/util";

interface Props {
  sections: object[];
  sectionSizes: number[];
  sectionHeaders: string;
  currentTimeString: string;
  overhead: boolean;
  isDummy?: boolean;
}

const SectionList = React.forwardRef(
  (
    {
      sections,
      sectionSizes,
      sectionHeaders,
      currentTimeString,
      overhead,
      isDummy = false,
    }: Props,
    ref
  ): JSX.Element => {
    const className = isDummy
      ? classWithModifier("section-list", "dummy")
      : "section-list";

    return (
      <div className={className} ref={ref}>
        {sections.map((section, i) => {
          const SectionComponent = section?.paging?.is_enabled
            ? PagedSection
            : Section;

          return (
            <SectionComponent
              {...section}
              numRows={sectionSizes[i]}
              sectionHeaders={sectionHeaders}
              currentTimeString={currentTimeString}
              overhead={overhead}
              key={section.name}
            />
          );
        })}
      </div>
    );
  }
);

export default SectionList;

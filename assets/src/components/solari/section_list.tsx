import React from "react";

import { PagedSection, Section } from "Components/solari/section";
import { classWithModifier } from "Util/util";

interface Props {
  sections: any[];
  sectionSizes: number[];
  sectionHeaders: string;
  currentTimeString: string;
  overhead: boolean;
  stationName: string;
  isDummy?: boolean;
}

const SectionList = React.forwardRef<HTMLDivElement, Props>(
  (
    {
      sections,
      sectionSizes,
      sectionHeaders,
      currentTimeString,
      overhead,
      stationName,
      isDummy = false,
    },
    ref,
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
              isAnimated={!isDummy}
              key={section.name}
              stationName={stationName}
            />
          );
        })}
      </div>
    );
  },
);

export default SectionList;

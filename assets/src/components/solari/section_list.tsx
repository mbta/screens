import React, { useRef, useState, useLayoutEffect } from "react";

import { PagedSection, Section } from "Components/solari/section";

const totalRows = (sections) => {
  return sections.reduce((acc, section) => {
    if (section.paging && section.paging.is_enabled === true) {
      return acc + section.paging.visible_rows;
    } else {
      return acc + section.departures.length;
    }
  }, 0);
};

const assignSectionSizes = (sections, numRows) => {
  const initialSizes = sections.map((section) => {
    if (section.paging && section.paging.is_enabled === true) {
      return section.paging.visible_rows;
    } else {
      return section.departures.length;
    }
  }, []);

  const initialRows = initialSizes.reduce((a, b) => a + b, 0);
  // const scaledSizes = initialSizes.map(n => (n * numRows / initialRows));
  const scaledSizes = initialSizes.map((n) =>
    Math.round((n * numRows) / initialRows)
  );

  return scaledSizes;
};

const SectionList = ({
  sections,
  showSectionHeaders,
  currentTimeString,
}): JSX.Element => {
  const MAX_DEPARTURES_HEIGHT = 1565;

  const ref = useRef(null);
  const initialRows = totalRows(sections);
  const initialSizes = assignSectionSizes(sections, initialRows);
  const initialState = { numRows: initialRows, sectionSizes: initialSizes };
  const [state, setState] = useState(initialState);

  useLayoutEffect(() => {
    if (ref.current) {
      const departuresHeight = ref.current.clientHeight;

      if (departuresHeight > MAX_DEPARTURES_HEIGHT && state.numRows > 5) {
        const newRows = state.numRows - 1;
        const newSizes = assignSectionSizes(sections, newRows);
        const newState = { numRows: newRows, sectionSizes: newSizes };
        setState(newState);
      }
    }
  });

  return (
    <div className="section-list" ref={ref}>
      {sections.map((section, i) => {
        if (section.paging && section.paging.is_enabled === true) {
          return (
            <PagedSection
              {...section}
              numRows={state.sectionSizes[i]}
              showSectionHeaders={showSectionHeaders}
              currentTimeString={currentTimeString}
              key={section.name + state.sectionSizes[i] + currentTimeString}
            />
          );
        } else {
          return (
            <Section
              {...section}
              numRows={state.sectionSizes[i]}
              showSectionHeaders={showSectionHeaders}
              currentTimeString={currentTimeString}
              key={section.name + state.sectionSizes[i] + currentTimeString}
            />
          );
        }
      })}
    </div>
  );
};

export default SectionList;

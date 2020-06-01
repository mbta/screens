import React, { useRef, useState, useLayoutEffect } from "react";
import _ from "lodash";

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

const allRoundings = (
  obj: Record<number, number>
): Record<number, number>[] => {
  return _.reduce(
    obj,
    (list, n, key) => {
      const floors = list.map((o) => ({ ...o, [key]: Math.floor(n) }));
      const ceils = list.map((o) => ({ ...o, [key]: Math.ceil(n) }));
      return [...floors, ...ceils];
    },
    [{}]
  );
};

const assignSectionSizes = (sections: object[], numRows: number): number[] => {
  // set the sizes for all empty sections to 1, to accomodate the "no departures" placeholder message
  const indexedAssignedEmpties = _.mapValues(
    _.pickBy({ ...sections }, (section) => section.departures.length === 0),
    () => 1
  );

  const indexedNonEmpties = _.pickBy(
    { ...sections },
    (section) => section.departures.length > 0
  );

  const indexedAssignedNonEmpties = assignSectionSizesHelper(
    indexedNonEmpties,
    numRows - _.size(indexedAssignedEmpties)
  );

  // merge the objects and convert back to an array
  return Array.from({
    ...indexedAssignedEmpties,
    ...indexedAssignedNonEmpties,
    length: _.size(indexedAssignedEmpties) + _.size(indexedAssignedNonEmpties),
  });
};

const assignSectionSizesHelper = (
  sections: Record<number, object>,
  numRows: number
): Record<number, number> => {
  const initialSizes = _.mapValues(sections, (section) => {
    if (section?.paging?.is_enabled) {
      return section.paging.visible_rows;
    } else {
      return section.departures.length;
    }
  });

  const initialRows = _.sum(Object.values(initialSizes));
  const scaledSizes = _.mapValues(
    initialSizes,
    (n) => (n * numRows) / initialRows
  );

  // Choose "best" rounding
  const allSizeCombinations = allRoundings(scaledSizes);
  const validSizeCombinations = allSizeCombinations.filter(
    (comb) => _.sum(Object.values(comb)) === numRows
  );
  const roundedSizes = _.minBy(validSizeCombinations, (comb) => {
    return _.sum(
      _.map(comb, (rounded, i) => Math.abs(rounded - scaledSizes[i]))
    );
  });

  return roundedSizes;
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

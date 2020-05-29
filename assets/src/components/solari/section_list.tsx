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

const allRoundings = (arr) => {
  return arr.reduce(
    (list, elt) => {
      const floors = list.map((l) => [...l, Math.floor(elt)]);
      const ceils = list.map((l) => [...l, Math.ceil(elt)]);
      return floors.concat(ceils);
    },
    [[]]
  );
};

const assignSectionSizes = (sections, numRows): number[] => {
  // split empty and non-empty sections into two arrays, keeping track of their original indices
  const [indexedEmpties, indexedNonEmpties] = sections.reduce(
    ([empties, nonEmpties], section, i) => [
      section.departures.length === 0 ? [...empties, [i, section]] : empties,
      section.departures.length > 0
        ? [...nonEmpties, [i, section]]
        : nonEmpties,
    ],
    [[], []]
  );

  // set the sizes for all empty sections to 1, to accomodate the "no departures" placeholder message
  const indexedAssignedEmpties = indexedEmpties.map(([i]) => [i, 1]);

  // get the non-empty sections, assign sizes to them, and then rejoin them with their original indices
  let indexedAssignedNonEmpties: [number, number][] = [];
  if (indexedNonEmpties.length > 0) {
    const [nonEmptyIndices, nonEmpties] = _.unzip(indexedNonEmpties);
    const assignedNonEmpties = assignSectionSizesImpl(
      nonEmpties,
      numRows - indexedEmpties.length
    );
    indexedAssignedNonEmpties = _.zip(nonEmptyIndices, assignedNonEmpties);
  }

  // combine the arrays, restore the original order of elements, and drop the indices
  return [...indexedAssignedEmpties, ...indexedAssignedNonEmpties]
    .sort(([i1], [i2]) => i1 - i2)
    .map(([_i, v]) => v);
};

const assignSectionSizesImpl = (sections, numRows): number[] => {
  const initialSizes = sections.map((section) => {
    if (section?.paging?.is_enabled) {
      return section.paging.visible_rows;
    } else {
      return section.departures.length;
    }
  }, []);

  const initialRows = _.sum(initialSizes);
  const scaledSizes = initialSizes.map((n) => (n * numRows) / initialRows);

  // Choose "best" rounding
  const allSizeCombinations = allRoundings(scaledSizes);
  const validSizeCombinations = allSizeCombinations.filter(
    (comb) => _.sum(comb) === numRows
  );
  const roundedSizes = _.minBy(validSizeCombinations, (comb) => {
    return _.sum(comb.map((rounded, i) => Math.abs(rounded - scaledSizes[i])));
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

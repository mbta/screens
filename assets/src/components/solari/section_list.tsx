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

const arraySum = (arr) => arr.reduce((acc, n) => acc + n, 0);

const minBy = (arr, fn) => {
  const min = arr.reduce(
    ({ elt, value }, newElt) => {
      const newValue = fn(newElt);
      if (newValue < value) {
        return { elt: newElt, value: newValue };
      } else {
        return { elt, value };
      }
    },
    { elt: null, value: Number.MAX_SAFE_INTEGER }
  );

  return min.elt;
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

const assignSectionSizes = (sections, numRows) => {
  const initialSizes = sections.map((section) => {
    if (section?.paging?.is_enabled) {
      return section.paging.visible_rows;
    } else {
      return section.departures.length;
    }
  }, []);

  const initialRows = arraySum(initialSizes);
  const scaledSizes = initialSizes.map((n) => (n * numRows) / initialRows);

  // Choose "best" rounding
  const allSizeCombinations = allRoundings(scaledSizes);
  const validSizeCombinations = allSizeCombinations.filter(
    (comb) => arraySum(comb) === numRows
  );
  const roundedSizes = minBy(validSizeCombinations, (comb) => {
    return arraySum(
      comb.map((rounded, i) => Math.abs(rounded - scaledSizes[i]))
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

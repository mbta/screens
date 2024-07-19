import _ from "lodash";

import type {
  Layout,
  NormalSection,
  FoldedNormalSection,
} from "./normal_section";
import NoticeSection from "./notice_section";

export type Section =
  | (NormalSection & { type: "normal_section" })
  | (NoticeSection & { type: "notice_section" });

export type FoldedSection =
  | (FoldedNormalSection & { type: "folded_section" })
  | (NoticeSection & { type: "notice_section" });

export const toFoldedSection = (section: Section): FoldedSection => {
  switch (section.type) {
    case "normal_section": {
      const foldedSection: FoldedSection = {
        ...section,
        type: "folded_section",
        rows: {
          aboveFold: section.rows,
          belowFold: [],
        },
      };

      if (section.layout.max) {
        const length = sectionLength(foldedSection);

        for (let l = length; l > section.layout.max; l--)
          trimSection(foldedSection);
      }

      return foldedSection;
    }

    case "notice_section":
      return section;
  }
};

/**
 * Perform one iteration of "section trimming", i.e. the process of shifting
 * departures from above-the-fold to below-the-fold while respecting sections'
 * desired layouts, until they all fit in a container without overflow.
 *
 * Operates immutably. If no sections could be trimmed, returns the same array.
 */
export const trimSections = (sections: FoldedSection[]): FoldedSection[] => {
  const trimmed = _.cloneDeep(sections);

  const sortedSizedSections = trimmed
    .map((section) => ({ section, length: sectionLength(section) }))
    .sort(({ length: a }, { length: b }) => b - a);

  for (const trimStage of [trimOneTowardsBase, trimOneTowardsMin]) {
    if (trimStage(sortedSizedSections)) return trimmed;
  }

  return sections;
};

// Determine how many above-the-fold departure "items" a section contains, for
// the purposes of deciding which sections should be trimmed first.
const sectionLength = (section: FoldedSection): number => {
  if (section.type == "folded_section") {
    return section.rows.aboveFold.reduce(
      (sum, row) =>
        sum +
        (row.type == "departure_row" ? row.times_with_crowding.length : 1),
      0,
    );
  } else {
    return 0;
  }
};

type SizedFoldedSection = {
  length: number;
  section: FoldedSection;
};

// `trimOne` functions destructively trim departures from sections, returning
// `true` if any trimming occurred. Each iteration of section trimming tries
// each function in sequence until one succeeds or they have all been tried.
// They assume the given sections are reverse-sorted by length (largest first).

// Trim one departure from the section with the most, among those with more than
// their `base`. If no `base` is defined, acts as `trimTowardsMin`.
const trimOneTowardsBase = (sections: SizedFoldedSection[]): boolean =>
  trimOneBy(sections, (length, { min, base }) => length > (base || min));

// Trim one departure from the section with the most, among those with more than
// their `min`.
const trimOneTowardsMin = (sections: SizedFoldedSection[]): boolean =>
  trimOneBy(sections, (length, { min }) => length > min);

const trimOneBy = (
  sections: SizedFoldedSection[],
  condition: (length: number, layout: Layout) => boolean,
): boolean => {
  for (const { section, length } of sections) {
    if (section.type == "folded_section" && condition(length, section.layout)) {
      if (trimSection(section)) return true;
    }
  }

  return false;
};

// Destructively shift the last above-the-fold departure time in a section to
// below-the-fold, if possible. Returns `true` if the section was trimmed.
const trimSection = (section: FoldedSection): boolean => {
  if (section.type == "folded_section") {
    const {
      rows: { aboveFold, belowFold },
    } = section;

    for (let aboveIndex = aboveFold.length - 1; aboveIndex >= 0; aboveIndex--) {
      const row = aboveFold[aboveIndex];

      if (row.type == "departure_row") {
        const trimmedTimeWithCrowding = _.last(row.times_with_crowding);

        if (row.times_with_crowding.length > 1) {
          // More than one departure time; trim the last one.
          row.times_with_crowding.splice(row.times_with_crowding.length - 1);
        } else {
          // Only one departure time; trim this row entirely.
          aboveFold.splice(aboveIndex, 1);
        }

        if (trimmedTimeWithCrowding != null) {
          belowFold.unshift({
            ...row,
            id: _.uniqueId(`${row.id}_`),
            times_with_crowding: [trimmedTimeWithCrowding],
          });
        }

        return true;
      }
    }
  }

  return false;
};

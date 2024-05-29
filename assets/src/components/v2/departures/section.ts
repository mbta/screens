import _ from "lodash";

import type {
  Layout,
  NormalSection,
  NormalSectionWithLaterRows,
} from "./normal_section";
import NoticeSection from "./notice_section";

export type Section =
  | (NormalSection & { type: "normal_section" })
  | (NoticeSection & { type: "notice_section" });

export type SectionWithLaterRows =
  | (NormalSectionWithLaterRows & { type: "normal_section" })
  | (NoticeSection & { type: "notice_section" });

export const toSectionWithLaterRows = (
  section: Section,
): SectionWithLaterRows => {
  if (section.type !== "normal_section") return section;

  return {
    ...section,
    laterRows: [],
  };
};

/**
 * Perform one iteration of "section trimming", i.e. the process of removing
 * departures from sections while respecting their desired layouts until they
 * all fit in a container without overflow.
 *
 * Operates immutably. If no sections could be trimmed, returns the same array.
 */
export const trimSections = (
  sections: SectionWithLaterRows[],
): SectionWithLaterRows[] => {
  const trimmed = _.cloneDeep(sections);

  const sortedSizedSections = trimmed
    .map((section) => ({ section, length: sectionLength(section) }))
    .sort(({ length: a }, { length: b }) => b - a);

  for (const trimStage of Object.values(trimStages)) {
    if (trimStage(sortedSizedSections)) return trimmed;
  }

  return sections;
};

// Determine how many "items" a section contains, for the purposes of deciding
// which sections should be trimmed first.
const sectionLength = (section: Section | SectionWithLaterRows): number => {
  if (section.type == "normal_section") {
    return section.rows.reduce(
      (sum, row) =>
        sum +
        (row.type == "departure_row" ? row.times_with_crowding.length : 1),
      0,
    );
  } else {
    return 0;
  }
};

type SizedSectionWithLaterRows = {
  length: number;
  section: SectionWithLaterRows;
};

// Functions which destructively trim departures from sections, returning `true`
// if any trimming occurred. Each iteration of section trimming tries each one
// of these in sequence until one succeeds or they have all been tried. Assumes
// the given sections are reverse-sorted by length (largest first).
const trimStages: Record<
  string,
  (sections: SizedSectionWithLaterRows[]) => boolean
> = {
  // Trim all sections with more departures than their `max` until they have
  // exactly as many as their `max` (if defined).
  allToMax: (sections) => {
    return sections.reduce((didTrim, { section, length }) => {
      if (section.type == "normal_section" && section.layout.max) {
        for (let l = length; l > section.layout.max; l--) {
          if (trimSection(section)) {
            // Trimmed this section; may be able to trim more, so keep going.
            didTrim ||= true;
          } else {
            // This section can't be trimmed further, so return early.
            return didTrim;
          }
        }
      }

      return didTrim;
    }, false);
  },

  // Trim one departure from the section with the most, among those with more
  // than their `base`. If no `base` is defined, acts as `oneOverMin`.
  oneTowardsBase: (sections) =>
    trimOneBy(sections, (length, { min, base }) => length > (base || min)),

  // Trim one departure from the section with the most, among those with more
  // than their `min`.
  oneTowardsMin: (sections) =>
    trimOneBy(sections, (length, { min }) => length > min),
};

const trimOneBy = (
  sections: SizedSectionWithLaterRows[],
  condition: (length: number, layout: Layout) => boolean,
): boolean => {
  for (const { section, length } of sections) {
    if (section.type == "normal_section" && condition(length, section.layout))
      if (trimSection(section)) return true;
  }

  return false;
};

// Destructively trim the last departure time from a section, if possible.
// Returns `true` if the section was trimmed.
const trimSection = (section: SectionWithLaterRows): boolean => {
  if (section.type == "normal_section") {
    for (let rowIndex = section.rows.length - 1; rowIndex >= 0; rowIndex--) {
      const row = section.rows[rowIndex];

      if (row.type == "departure_row") {
        const trimmedTimeWithCrowding = _.last(row.times_with_crowding);
        if (row.times_with_crowding.length > 1) {
          // More than one departure time; trim the last one.
          row.times_with_crowding.splice(row.times_with_crowding.length - 1);
        } else {
          // Only one departure time; trim this row entirely.
          section.rows.splice(rowIndex, 1);
        }

        if (trimmedTimeWithCrowding != null) {
          section.laterRows.unshift({
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

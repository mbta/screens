import type HeadwaySection from "Components/dup/departures/headway_section";
import type NoDataSection from "Components/dup/departures/no_data_section";
import type NoServiceSection from "Components/dup/departures/no_service_section";
import type OvernightSection from "Components/dup/departures/overnight_section";
import type {
  BaseFoldedSection,
  FoldedSection,
  NormalSection,
} from "Components/departures/normal_section";
import _ from "lodash";
// TODO: There is likely room to move the non-DUP stuff onto this, separate PR?
import { sectionLength, trimSection } from "Components/section_utils";

// TODO: I don't love the merging of the value and types here
type DupSectionBase =
  | (HeadwaySection & { type: "headway_section" })
  | (NoDataSection & { type: "no_data_section" })
  | (NoServiceSection & { type: "no_service_section" })
  | (OvernightSection & { type: "overnight_section" });

// TODO: I don't love the merging of the value and types here
/**
 *
 */
export type DupSection =
  (NormalSection & { type: "normal_section" }) | DupSectionBase;

/**
 *
 */
export type DupDepartureSection = FoldedSection | DupSectionBase;

// TODO: Fix
/**
 * Converts a {@link DupSection} into
 * @param dupSection
 * @returnsd
 */
export const toDupDepartureSection = (
  dupSection: DupSection,
): DupDepartureSection => {
  switch (dupSection.type) {
    case "headway_section":
    case "no_data_section":
    case "no_service_section":
    case "overnight_section": {
      return dupSection;
    }
    case "normal_section": {
      const foldedSection: FoldedSection =
        baseFoldedSectionToSpecialize(dupSection);

      if (foldedSection.layout.max) {
        const length = sectionLength(foldedSection);

        for (let l = length; l > foldedSection.layout.max; l--)
          trimSection(foldedSection);
      }

      return foldedSection;
    }
  }
};

const baseFoldedSectionToSpecialize = (
  dupNormalSection: NormalSection,
): FoldedSection => {
  const baseSection: BaseFoldedSection = {
    ...dupNormalSection,
    type: "folded_section",
    rows: {
      aboveFold: dupNormalSection.rows,
      belowFold: [],
    },
  };

  const directionCounts = _.countBy(dupNormalSection.rows, "direction_id");
  const directionPriority =
    (directionCounts[1] || 0) > (directionCounts[0] || 0) ? 0 : 1;

  switch (dupNormalSection.mode) {
    case "ferry":
      return {
        ...baseSection,
        grouping_type: "time",
      };
    default:
      return dupNormalSection.grouping_type === "destination"
        ? {
            ...baseSection,
            grouping_type: "destination",
            direction_trim_priority: directionPriority,
          }
        : {
            ...baseSection,
            grouping_type: "time",
          };
  }
};

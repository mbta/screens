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
 * @param section
 * @returnsd
 */
export const toDupDepartureSection = (
  section: DupSection,
): DupDepartureSection => {
  switch (section.type) {
    case "headway_section": {
      return section;
    }
    case "no_data_section": {
      return section;
    }
    case "no_service_section": {
      return section;
    }
    case "normal_section": {
      const baseSection: BaseFoldedSection = {
        ...section,
        type: "folded_section",
        rows: {
          aboveFold: section.rows,
          belowFold: [],
        },
      };

      // TODO: Replace lodash? Not as important rn
      const directionCounts = _.countBy(section.rows, "direction_id");
      const directionPriority =
        (directionCounts[1] || 0) > (directionCounts[0] || 0) ? 0 : 1;

      const foldedSection: FoldedSection =
        section.grouping_type === "destination"
          ? {
              ...baseSection,
              grouping_type: "destination",
              direction_trim_priority: directionPriority,
            }
          : {
              ...baseSection,
              grouping_type: "time",
            };

      if (foldedSection.layout.max) {
        const length = sectionLength(foldedSection);

        for (let l = length; l > foldedSection.layout.max; l--)
          trimSection(foldedSection);
      }

      return foldedSection;
    }
    case "overnight_section": {
      return section;
    }
  }
};

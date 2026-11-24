import type HeadwaySection from "Components/dup/departures/headway_section";
import type NoDataSection from "Components/dup/departures/no_data_section";
import type NoServiceSection from "Components/dup/departures/no_service_section";
import type OvernightSection from "Components/dup/departures/overnight_section";
import type { NormalSection } from "Components/departures/normal_section";

// TODO: I don't love the merging of the value and types here
/**
 *
 */
export type DupSection =
  | (NormalSection & { type: "normal_section" })
  | (HeadwaySection & { type: "headway_section" })
  | (NoDataSection & { type: "no_data_section" })
  | (NoServiceSection & { type: "no_service_section" })
  | (OvernightSection & { type: "overnight_section" });

// TODO: Fix
/**
 * Converts a {@link DupSection} into
 * @param section
 * @returnsd
 */
export const toDupDepartureSection = (section: DupSection): DupSection => {
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
      throw new Error('Not implemented yet: "normal_section" case');
    }
    case "overnight_section": {
      return section;
    }
  }
};

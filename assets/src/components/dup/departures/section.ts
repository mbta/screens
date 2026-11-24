import type { Section as SectionBase } from "Components/departures/section";
import HeadwaySection from "Components/dup/departures/headway_section";
import NoDataSection from "Components/dup/departures/no_data_section";
import NoServiceSection from "Components/dup/departures/no_service_section";
import OvernightSection from "Components/dup/departures/overnight_section";

export type DupSection =
  | SectionBase
  | (HeadwaySection & { type: "headway_section" })
  | (NoDataSection & { type: "no_data_section" })
  | (NoServiceSection & { type: "no_service_section" })
  | (OvernightSection & { type: "overnight_section" });

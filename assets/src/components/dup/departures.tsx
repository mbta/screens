import type { ComponentType } from "react";

import { type Section as SectionBase } from "Components/departures/section";
import NormalSection from "./departures/normal_section";
import HeadwaySection from "./departures/headway_section";
import NoDataSection from "./departures/no_data_section";
import NoServiceSection from "./departures/no_service_section";
import OvernightSection from "./departures/overnight_section";

type Section =
  | SectionBase
  | (HeadwaySection & { type: "headway_section" })
  | (NoDataSection & { type: "no_data_section" })
  | (NoServiceSection & { type: "no_service_section" })
  | (OvernightSection & { type: "overnight_section" });

interface Props {
  sections: Section[];
}

const Departures: ComponentType<Props> = ({ sections }) => {
  return (
    <div className="departures-container">
      <div className="departures">
        {sections.map((section, i) => {
          switch (section.type) {
            case "normal_section":
              return <NormalSection {...section} key={i} />;
            case "headway_section":
              return <HeadwaySection {...section} key={i} />;
            case "no_data_section":
              return <NoDataSection {...section} key={i} />;
            case "no_service_section":
              return <NoServiceSection {...section} key={i} />;
            case "overnight_section":
              return <OvernightSection {...section} key={i} />;
          }
        })}
      </div>
    </div>
  );
};

export default Departures;

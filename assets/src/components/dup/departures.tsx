import type { ComponentType } from "react";

import NormalSection from "./departures/normal_section";
import HeadwaySection from "./departures/headway_section";
import NoDataSection from "./departures/no_data_section";
import NoServiceSection from "./departures/no_service_section";
import OvernightSection from "./departures/overnight_section";
import {
  DupSection,
  toDupDepartureSection,
} from "Components/dup/departures/section";

interface DeparturesProps {
  sections: DupSection[];
}

const Departures: ComponentType<DeparturesProps> = ({ sections }) => {
  const f = sections.map(toDupDepartureSection);
  return (
    <div className="departures-container">
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
  );
};

export default Departures;

import React, { ComponentType } from "react";

import { type Section as SectionBase } from "Components/v2/departures/section";
import NormalSection from "../dup/departures/normal_section";
import HeadwaySection from "../dup/departures/headway_section";
import NoDataSection from "../dup/departures/no_data_section";
import OvernightSection from "../dup/departures/overnight_section";
import DeparturesHeader from "./departures_header";

type Section =
  | SectionBase
  | (HeadwaySection & { type: "headway_section" })
  | (NoDataSection & { type: "no_data_section" })
  | (OvernightSection & { type: "overnight_section" });

interface Props {
  sections: Section[];
}

const Departures: ComponentType<Props> = ({ sections }) => {
  return (
    <div className="departures-container">
      <div className="departures-header"><DeparturesHeader/></div>
      <div className="departures">
        {sections.map((section, i) => {
          switch (section.type) {
            case "normal_section":
              return <NormalSection {...section} key={i} />;
            case "headway_section":
              return <HeadwaySection {...section} key={i} />;
            case "no_data_section":
              return <NoDataSection {...section} key={i} />;
            case "overnight_section":
              return <OvernightSection {...section} key={i} />;
          }
        })}
      </div>
    </div>
  );
};

export default Departures;

import React, { ComponentType } from "react";

import { NormalSection, NormalSectionProps } from "./normal_section";
import NoData from "./no_data";
import DeparturesHeader from "./departures_header";

type Section =
  | (NormalSectionProps & { type: "normal_section" })
  | (NoData & { type: "no_data_section" });

interface Props {
  sections: Section[];
  includeHeader: boolean;
}

const Departures: ComponentType<Props> = ({ sections }) => {
  console.log(sections);
  return (
    <div className="departures-container">
      <div className="departures-header">
        <DeparturesHeader />
      </div>
      <div className="departures">
        {sections.map((section, i) => {
          switch (section.type) {
            case "normal_section":
              return <NormalSection rows={section.rows} key={i} />;
            case "no_data_section":
              return <NoData {...section} key={i} />;
          }
        })}
      </div>
    </div>
  );
};

export default Departures;

import {ComponentType, useLayoutEffect, useMemo, useRef, useState} from "react";

import NormalSection from "./departures/normal_section";
import HeadwaySection from "./departures/headway_section";
import NoDataSection from "./departures/no_data_section";
import NoServiceSection from "./departures/no_service_section";
import OvernightSection from "./departures/overnight_section";
import {
  DupSection,
  toDupDepartureSection,
} from "Components/dup/departures/section";
import {hasOverflowY} from "Util/utils";
import {report} from "Util/sentry";
import {trimSections} from "Components/section_utils";

interface DeparturesProps {
  sections: DupSection[];
}

const Departures: ComponentType<DeparturesProps> = ({ sections }) => {
  const ref = useRef<HTMLDivElement>(null);
  const initialSections = useMemo(
      () => sections.map(toDupDepartureSection),
      [sections],
  );
  const [departureSections, setDepartureSections] = useState(initialSections);

  // Restart trimming if the original sections are changed (i.e. new data).
  useLayoutEffect(
      // eslint-disable-next-line react-hooks/set-state-in-effect
      () => setDepartureSections(initialSections),
      [initialSections],
  );

  // Iteratively trim sections until the container doesn't overflow.
  useLayoutEffect(() => {
    if (ref.current && hasOverflowY(ref.current)) {
      const newSections = trimSections(departureSections);

      if (departureSections !== newSections) {
        // eslint-disable-next-line react-hooks/set-state-in-effect
        setDepartureSections(newSections);
      } else {
        report("warning", "layout failed: departures will overflow");
      }
    }
  }, [departureSections]);

  return (
    <div className="departures-container">
      {departureSections.map((section, i) => {
        switch (section.type) {
          case "folded_section":
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

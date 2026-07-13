import {
  ComponentType,
  useLayoutEffect,
  useMemo,
  useRef,
  useState,
} from "react";
import weakKey from "weak-key";

import { NormalSection } from "./departures/normal_section";
import {
  Section,
  trimSections,
  toDepartureSection,
} from "./departures/section";

import { report } from "Util/sentry";
import { hasOverflowY } from "Util/utils";
import { OvernightSection } from "./departures/overnight_section";

type Departures = {
  sections: Section[];
};

const Departures: ComponentType<Departures> = ({ sections }) => {
  const ref = useRef<HTMLDivElement>(null);
  const initialSections = useMemo(
    () => sections.map(toDepartureSection),
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
    <div className="departures-container" ref={ref}>
      {departureSections.map((section) => {
        switch (section.type) {
          case "overnight_section": {
            return <OvernightSection {...section} key={weakKey(section)} />;
          }

          case "folded_section": {
            return <NormalSection {...section} key={weakKey(section)} />;
          }
        }
      })}
    </div>
  );
};

export default Departures;

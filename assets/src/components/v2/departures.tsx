import React, {
  ComponentType,
  useLayoutEffect,
  useMemo,
  useRef,
  useState,
} from "react";
import weakKey from "weak-key";

import NormalSection from "./departures/normal_section";
import { Section, trimSections, toFoldedSection } from "./departures/section";

import { warn } from "Util/sentry";
import { hasOverflowY } from "Util/utils";

type Departures = {
  sections: Section[];
};

const Departures: ComponentType<Departures> = ({ sections }) => {
  const ref = useRef<HTMLDivElement>(null);
  const initialSections = useMemo(
    () => sections.map(toFoldedSection),
    [sections],
  );
  const [foldedSections, setFoldedSections] = useState(initialSections);

  // Restart trimming if the original sections are changed (i.e. new data).
  useLayoutEffect(() => setFoldedSections(initialSections), [initialSections]);

  // Iteratively trim sections until the container doesn't overflow.
  useLayoutEffect(() => {
    if (hasOverflowY(ref)) {
      const newSections = trimSections(foldedSections);

      if (foldedSections != newSections) {
        setFoldedSections(newSections);
      } else {
        warn("layout failed: departures will overflow");
      }
    }
  }, [foldedSections]);

  return (
    <div className="departures-container" ref={ref}>
      {foldedSections.map((section) => {
        return <NormalSection {...section} key={weakKey(section)} />;
      })}
    </div>
  );
};

export default Departures;

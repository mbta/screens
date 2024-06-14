import React, {
  ComponentType,
  useLayoutEffect,
  useMemo,
  useRef,
  useState,
} from "react";
import weakKey from "weak-key";

import NormalSection from "./normal_section";
import NoticeSection from "./notice_section";
import { Section, trimSections, toFoldedSection } from "./section";

import { warn } from "Util/sentry";
import { hasOverflowY } from "Util/util";

type NormalDepartures = {
  sections: Section[];
};

const NormalDepartures: ComponentType<NormalDepartures> = ({ sections }) => {
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
        const key = weakKey(section);

        if (section.type === "folded_section") {
          return <NormalSection {...section} key={key} />;
        } else {
          return <NoticeSection {...section} key={key} />;
        }
      })}
    </div>
  );
};

export default NormalDepartures;

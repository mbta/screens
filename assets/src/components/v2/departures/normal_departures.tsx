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
import { Section, trimSections, toSectionWithLaterRows } from "./section";

import { warn } from "Util/sentry";
import { hasOverflowY } from "Util/util";

type NormalDepartures = {
  sections: Section[];
};

const NormalDepartures: ComponentType<NormalDepartures> = ({ sections }) => {
  const ref = useRef<HTMLDivElement>(null);
  const sectionsWithLaterRows = useMemo(
    () => sections.map(toSectionWithLaterRows),
    [sections],
  );
  const [trimmedSections, setTrimmedSections] = useState(sectionsWithLaterRows);

  // Restart trimming if the sections prop is changed (i.e. new data).
  useLayoutEffect(
    () => setTrimmedSections(sectionsWithLaterRows),
    [sectionsWithLaterRows],
  );

  // Iteratively trim sections until the container doesn't overflow.
  useLayoutEffect(() => {
    if (hasOverflowY(ref)) {
      const newSections = trimSections(trimmedSections);

      if (trimmedSections != newSections) {
        setTrimmedSections(newSections);
      } else {
        warn("layout failed: departures will overflow");
      }
    }
  }, [trimmedSections]);

  return (
    <div className="departures-container" ref={ref}>
      {trimmedSections.map((section) => {
        const key = weakKey(section);

        if (section.type === "normal_section") {
          return <NormalSection {...section} key={key} />;
        } else {
          return <NoticeSection {...section} key={key} />;
        }
      })}
    </div>
  );
};

export default NormalDepartures;

import React, {
  ComponentType,
  useState,
  forwardRef,
  useLayoutEffect,
  useRef,
  useEffect,
  useContext,
} from "react";
import weakKey from "weak-key";

import NormalSection, {
  Row as NormalRow,
} from "Components/v2/departures/normal_section";
import NoticeSection from "Components/v2/departures/notice_section";
import { LastFetchContext } from "../screen_container";

type Section =
  | (NormalSection & { type: "normal_section" })
  | (NoticeSection & { type: "notice_section" });

type RendererProps = {
  sections: Section[];
  sectionSizes: number[];
};

const NormalDeparturesRenderer = forwardRef<HTMLDivElement, RendererProps>(
  ({ sections, sectionSizes }, ref) => {
    return (
      <div className="departures-container">
        <div className="departures" ref={ref}>
          {sections.map((section, i) => {
            const key = weakKey(section);

            if (section.type === "normal_section") {
              return (
                <NormalSection
                  rows={trimRows(section.rows, sectionSizes[i])}
                  key={key}
                />
              );
            } else {
              return <NoticeSection {...section} key={key} />;
            }
          })}
        </div>
      </div>
    );
  },
);

const trimRows = (rows, n) => {
  const { trimmed } = rows.reduce(
    ({ count, trimmed }, row: NormalRow) => {
      if (row.type == "notice_row") {
        if (count < n) {
          return { count: count + 1, trimmed: [...trimmed, row] };
        } else {
          return { count, trimmed };
        }
      }

      const trimmedRow = {
        ...row,
        times_with_crowding: row.times_with_crowding.slice(0, n - count),
      };
      const addedCount = trimmedRow.times_with_crowding.length;

      if (addedCount > 0) {
        return { count: count + addedCount, trimmed: [...trimmed, trimmedRow] };
      } else {
        return { count, trimmed };
      }
    },
    { count: 0, trimmed: [] },
  );

  return trimmed;
};

const getInitialSectionSize = (data) => {
  return data.rows.reduce((acc, row: NormalRow) => {
    switch (row.type) {
      case "departure_row":
        return acc + row.times_with_crowding.length;
      case "notice_row":
        return acc + 1;
    }
  }, 0);
};

const getInitialSectionSizes = (sections) => {
  return sections.map((section) => getInitialSectionSize(section));
};

const NormalDeparturesSizer = ({ sections, onDoneSizing }) => {
  const [tempSectionSizes, setTempSectionSizes] = useState(
    getInitialSectionSizes(sections),
  );
  const ref = useRef<HTMLDivElement>(null);

  useLayoutEffect(() => {
    if (
      ref.current?.parentElement?.parentElement &&
      ref.current.clientHeight >
        ref.current.parentElement.parentElement.clientHeight
    ) {
      setTempSectionSizes((sectionSizes) => {
        return [sectionSizes[0] - 1];
      });
    } else {
      onDoneSizing(tempSectionSizes);
    }
  }, [sections, tempSectionSizes]);

  return (
    <NormalDeparturesRenderer
      sections={sections}
      sectionSizes={tempSectionSizes}
      ref={ref}
    />
  );
};

type NormalDepartures = {
  sections: Section[];
};

const NormalDepartures: ComponentType<NormalDepartures> = ({ sections }) => {
  const [sectionSizes, setSectionSizes] = useState([]);
  const lastFetch = useContext(LastFetchContext);

  // Reset state each time we receive new props,
  // so that section sizes are recalculated from scratch.
  useEffect(() => {
    setSectionSizes([]);
  }, [sections]);

  if (sectionSizes.length > 0) {
    return (
      <NormalDeparturesRenderer
        sections={sections}
        sectionSizes={sectionSizes}
        key={lastFetch}
      />
    );
  } else {
    return (
      <NormalDeparturesSizer
        sections={sections}
        onDoneSizing={setSectionSizes}
        key={lastFetch}
      />
    );
  }
};

export default NormalDepartures;

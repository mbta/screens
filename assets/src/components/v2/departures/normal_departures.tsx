import React, {
  useState,
  forwardRef,
  useLayoutEffect,
  useRef,
  useEffect,
} from "react";

import NormalSection from "Components/v2/departures/normal_section";

const NormalDeparturesRenderer = forwardRef(
  ({ sections, sectionSizes }, ref) => {
    return (
      <div className="departures-container">
        <div className="departures" ref={ref}>
          {sections.map(({ type, ...data }, i) => {
            if (type === "normal_section") {
              const { rows } = data;
              return (
                <NormalSection rows={trimRows(rows, sectionSizes[i])} key={i} />
              );
            } else if (type === "notice_section") {
              return <NoticeSection {...data} key={i} />;
            }
          })}
        </div>
      </div>
    );
  }
);

const trimRows = (rows, n) => {
  const { trimmed, count } = rows.reduce(
    ({ count, trimmed }, row: Row) => {
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
    { count: 0, trimmed: [] }
  );

  return trimmed;
};

interface DepartureRow {
  type: "departure_row";
  times_with_crowding: any[];
}

interface NoticeRow {
  type: "notice_row";
  text: object;
}

type Row = DepartureRow | NoticeRow;

const getInitialSectionSize = (data) => {
  return data.rows.reduce(
    (acc, row: Row) => {
      switch (row.type) {
        case "departure_row":
          return acc + row.times_with_crowding.length;
        case "notice_row":
          return acc + 1;
      }
    }, 0
  );
};

const getInitialSectionSizes = (sections) => {
  return sections.map((section) => getInitialSectionSize(section));
};

const NormalDeparturesSizer = ({ sections, onDoneSizing }) => {
  const [tempSectionSizes, setTempSectionSizes] = useState(
    getInitialSectionSizes(sections)
  );
  const ref = useRef();

  useLayoutEffect(() => {
    if (
      ref.current &&
      ref.current.clientHeight > ref.current.parentNode.parentNode.clientHeight
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

const NormalDepartures = ({ sections }) => {
  const [sectionSizes, setSectionSizes] = useState([]);

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
      />
    );
  } else {
    return (
      <NormalDeparturesSizer
        sections={sections}
        onDoneSizing={setSectionSizes}
      />
    );
  }
};

export default NormalDepartures;

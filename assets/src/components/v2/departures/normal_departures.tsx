import React, { useState, forwardRef, useLayoutEffect, useRef } from "react";

import NormalSection from "Components/v2/departures/normal_section";
import NoticeSection from "Components/v2/departures/notice_section";

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
  const trimmedRows = [];
  let trimmedRowCount = 0;
  let currentRowIndex = 0;

  while (trimmedRowCount < n && currentRowIndex < rows.length) {
    const currentRow = rows[currentRowIndex];
    if (trimmedRowCount + currentRow.times_with_crowding.length < n) {
      trimmedRows.push(currentRow);
      trimmedRowCount += currentRow.times_with_crowding.length;
    } else {
      const numTimes = n - trimmedRowCount;
      const trimmedTimes = currentRow.times_with_crowding.slice(0, numTimes);
      const trimmedRow = { ...currentRow, times_with_crowding: trimmedTimes };
      trimmedRows.push(trimmedRow);
      trimmedRowCount += trimmedRow.times_with_crowding.length;
    }

    currentRowIndex += 1;
  }

  return trimmedRows;
};

const getInitialSectionSize = ({ type, ...data }) => {
  if (type === "normal_section") {
    return data.rows.reduce(
      (acc, { times_with_crowding: times }) => acc + times.length,
      0
    );
  } else {
    return 0;
  }
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

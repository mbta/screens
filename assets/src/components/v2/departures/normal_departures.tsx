import React, { useState, forwardRef, useLayoutEffect, useRef } from "react";

import NormalSection from "Components/v2/departures/normal_section";
import NoticeSection from "Components/v2/departures/notice_section";

const NormalDeparturesRenderer = forwardRef(
  ({ sections, sectionSizes }, ref) => {
    return (
      <div className="departures" ref={ref}>
        {sections.map(({ type, ...data }, i) => {
          if (type === "normal_section") {
            const { rows } = data;
            return (
              <NormalSection rows={rows.slice(0, sectionSizes[i])} key={i} />
            );
          } else if (type === "notice_section") {
            return <NoticeSection {...data} key={i} />;
          }
        })}
      </div>
    );
  }
);

const getInitialSectionSize = ({ type, ...data }) => {
  if (type === "normal_section") {
    return data.rows.length;
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
      ref.current.clientHeight > ref.current.parentNode.clientHeight
    ) {
      setTempSectionSizes((sectionSizes) => {
        return [sectionSizes[0] - 1];
      });
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

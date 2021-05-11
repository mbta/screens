import React from "react";

import NormalSection from "Components/v2/departures/normal_section";
import NoticeSection from "Components/v2/departures/notice_section";

const NormalDepartures = ({ sections }) => {
  return (
    <div className="departures">
      {sections.map(({ type, ...data }, i) => {
        if (type === "normal_section") {
          return <NormalSection {...data} key={i} />;
        } else if (type === "notice_section") {
          return <NoticeSection {...data} key={i} />;
        }
      })}
    </div>
  );
};

export default NormalDepartures;

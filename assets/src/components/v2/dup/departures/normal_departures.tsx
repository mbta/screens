import React from "react";

import NormalSection from "Components/v2/dup/departures/normal_section";
import NoticeSection from "Components/v2/dup/departures/notice_section";

const NormalDepartures = ({ sections }) => {
  return (
    <div className="departures-container">
      <div className="departures">
        {sections.map(({ type, ...data }, i) => {
          if (type === "normal_section") {
            const { rows } = data;
            return <NormalSection rows={rows} key={i} />;
          } else if (type === "notice_section") {
            return <NoticeSection {...data} key={i} />;
          }
        })}
      </div>
    </div>
  );
};

export default NormalDepartures;

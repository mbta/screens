import React from "react";

import NormalSection from "Components/v2/dup/departures/normal_section";
import NoticeSection from "Components/v2/departures/notice_section";
import HeadwaySection from "Components/v2/dup/departures/headway_section";
import NoDataSection from "Components/v2/dup/departures/no_data_section";
import OvernightSection from "./overnight_section";

const NormalDepartures = ({ sections }) => {
  return (
    <div className="departures-container">
      <div className="departures">
        {sections.map(({ type, ...data }, i) => {
          switch (type) {
            case "normal_section":
              return <NormalSection rows={data.rows} key={i} />;
            case "notice_section":
              return <NoticeSection {...data} key={i} />;
            case "headway_section":
              return (
                <HeadwaySection text={data.text} layout={data.layout} key={i} />
              );
            case "no_data_section":
              return <NoDataSection text={data.text} key={i} />;
            case "overnight_section":
              return <OvernightSection text={data.text} key={i} />;
          }
        })}
      </div>
    </div>
  );
};

export default NormalDepartures;

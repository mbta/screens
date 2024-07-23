import React from "react";

import NormalSection from "./departures/normal_section";
import NoticeSection from "Components/v2/departures/notice_section";
import HeadwaySection from "./departures/headway_section";
import NoDataSection from "./departures/no_data_section";
import OvernightSection from "./departures/overnight_section";

const Departures = ({ sections }) => {
  return (
    <div className="departures-container">
      <div className="departures">
        {sections.map(({ type, ...data }, i) => {
          switch (type) {
            case "normal_section":
              return <NormalSection rows={data.rows} key={i} />;
            case "notice_section":
              return <NoticeSection text={data.text} key={i} />;
            case "headway_section":
              return (
                <HeadwaySection text={data.text} layout={data.layout} key={i} />
              );
            case "no_data_section":
              return <NoDataSection text={data.text} key={i} />;
            case "overnight_section":
              return <OvernightSection text={data.text} key={i} />;
          }

          throw new Error(`unimplemented section type: ${type}`);
        })}
      </div>
    </div>
  );
};

export default Departures;

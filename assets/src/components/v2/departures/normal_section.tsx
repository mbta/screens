import React from "react";

import DepartureRow from "Components/v2/departures/departure_row";
import NoticeRow from "./notice_row";

const NormalSection = ({ rows }) => {
  const departure_rows = rows.filter(({ type }) => type === "departure_row");
  const notice_rows = rows.filter(({ type }) => type === "notice_row");
  return (
    <div>
      <div className="departures-section">
        {departure_rows.filter(({ type }) => type === "departure_row").map((rowProps) => {
          const { id, ...data } = rowProps;
          return <DepartureRow {...data} key={id} />;
        })}
        {notice_rows.map((notice, index) => {
          return <NoticeRow row={notice} key={"notice" + index} />;
        })}
      </div>
    </div>
  );
};

export default NormalSection;

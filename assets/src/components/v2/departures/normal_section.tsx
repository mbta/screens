import React from "react";

import DepartureRow from "Components/v2/departures/departure_row";
import NoticeRow from "./notice_row";

const NormalSection = ({ rows, notice }) => {
  return (
    <div className="departures-section">
      {rows.map((rowProps) => {
        const { id, ...data } = rowProps;
        return <DepartureRow {...data} key={id} />;
      })}
      {(notice && rows.length > 0) && <div className="departures-hr" />}
      {notice && <NoticeRow row={notice} key={"notice"} />}
    </div>
  );
};

export default NormalSection;

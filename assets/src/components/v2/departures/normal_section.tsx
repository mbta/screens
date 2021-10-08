import React from "react";

import DepartureRow from "Components/v2/departures/departure_row";
import NoticeRow from "./notice_row";

const NormalSection = ({ rows }) => {
  return (
    <div>
      <div className="departures-section">
        {rows.map((row, index) => {
          const { id, type, ...data } = row;
          if (type === "departure_row") {
            return <DepartureRow {...data} key={id} />;
          } else if (type === "notice_row") {
            return <NoticeRow row={row} key={"notice" + index} />;
          }
        })}
      </div>
    </div>
  );
};

export default NormalSection;

import React from "react";

import DepartureRow from "Components/v2/dup/departures/departure_row";
import NoticeRow from "Components/v2/departures/notice_row";
import useCurrentPage from "Hooks/use_current_dup_page";

const NormalSection = ({ rows }) => {
  const currentPage = useCurrentPage();

  return (
    rows.length > 0 && (
      <div className="departures-section">
        {rows.map((row, index) => {
          const { id, type, ...data } = row;
          if (type === "departure_row") {
            return (
              <DepartureRow {...data} key={id} currentPage={currentPage} />
            );
          } else if (type === "notice_row") {
            return <NoticeRow row={row} key={"notice" + index} />;
          }
        })}
      </div>
    )
  );
};

export default NormalSection;

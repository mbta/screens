import type { ComponentType } from "react";

import { type NormalSection as Props } from "Components/v2/departures/normal_section";
import DepartureRow from "./departure_row";
import NoticeRow from "Components/v2/departures/notice_row";
import useCurrentPage from "Hooks/use_current_dup_page";

const NormalSection: ComponentType<Props> = ({ rows }) => {
  if (rows.length == 0) return null;

  const currentPage = useCurrentPage();

  return (
    <div className="departures-section">
      {rows.map((row, index) => {
        if (row.type === "departure_row") {
          return (
            <DepartureRow {...row} key={row.id} currentPage={currentPage} />
          );
        } else {
          return <NoticeRow row={row} key={"notice" + index} />;
        }
      })}
    </div>
  );
};

export default NormalSection;

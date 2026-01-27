import type { ComponentType } from "react";

import { type NormalSection as Props } from "Components/departures/normal_section";
import DepartureRow from "./departure_row";
import NoticeRow from "Components/departures/notice_row";

const NormalSection: ComponentType<Props> = ({ rows }) => {
  if (rows.length === 0) return null;

  return (
    <div className="departures-section">
      {rows.map((row, index) => {
        if (row.type === "departure_row") {
          return <DepartureRow {...row} key={row.id} />;
        } else {
          return <NoticeRow row={row} key={"notice" + index} />;
        }
      })}
    </div>
  );
};

export default NormalSection;

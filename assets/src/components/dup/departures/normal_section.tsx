import type { ComponentType } from "react";

import {
  Row,
  type NormalSection as Props,
} from "Components/departures/normal_section";
import DepartureRow from "./departure_row";
import NoticeRow from "Components/departures/notice_row";
import { classWithModifier } from "Util/utils";

const NormalSection: ComponentType<Props> = ({ rows }) => {
  if (rows.length === 0) return null;

  const classModifier = shortenHeadsignsForSection(rows)
    ? "shortened-headsigns"
    : "";

  return (
    <div className={classWithModifier("departures-section", classModifier)}>
      {rows.map((row, index) => {
        if (row.type === "departure_row") {
          // When the available width for headsigns changes, re-render the
          // departures so headsign abbreviation will be redone.
          return <DepartureRow {...row} key={row.id + classModifier} />;
        } else {
          return <NoticeRow row={row} key={"notice" + index} />;
        }
      })}
    </div>
  );
};

const shortenHeadsignsForSection = (rows: Row[]) => {
  // Stop away messages take up a larger block of space,
  // so we need to shorten the space designated for headsigns.
  return rows.some(
    (row) =>
      row.type === "departure_row" &&
      row.times_with_crowding?.some((time) => time.time?.type === "status"),
  );
};

export default NormalSection;

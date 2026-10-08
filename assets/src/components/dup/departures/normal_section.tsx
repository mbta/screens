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

  const classModifier = widestTimeType(rows);

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

const widestTimeType = (rows: Row[]): string => {
  const widestPriority = ["status", "headway", "first", "timestamp"];
  const timeTypes = new Set<string>();

  rows.forEach((row) => {
    if (row.type !== "departure_row") return;

    if (row.is_first_trip) {
      timeTypes.add("first");
      return;
    }

    (row.times_with_crowding ?? []).forEach((time) => {
      const type = time.time?.type;
      if (type) timeTypes.add(type);
    });
  });

  return widestPriority.find((type) => timeTypes.has(type)) ?? "";
};

export default NormalSection;

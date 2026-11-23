import type { ComponentType } from "react";

import {
  type Row,
  type NormalSection as NormalSectionProps,
} from "Components/departures/normal_section";
import DepartureRow from "./departure_row";
import NoticeRow from "Components/departures/notice_row";
import { classWithModifier } from "Util/utils";

// Used to calculate the time with the largest space requirements
// We then use this to set a fixed width to allow for the time to fit
// while letting the headsign take the rest of the space
// This is due to the DUP Chrome version being 51 preventing us from
// using more modern methods of dynamically giving space
const TIME_TYPE_PRIORITY = [
  "status",
  "headway",
  "first",
  "hours-and-minutes",
  "timestamp",
  "text",
  "minutes",
  "overnight",
];

const NormalSection: ComponentType<NormalSectionProps> = ({ rows }) => {
  if (rows.length === 0) return null;

  const classModifier = widestTimeType(rows);

  return (
    <div className={classWithModifier("departures-section", classModifier)}>
      {rows.map((row, index) => {
        if (row.type === "departure_row") {
          // When the available width for headsigns changes, re-render the
          // departures so headsign abbreviation will be redone.
          return <DepartureRow {...row} key={row.id + classModifier} />;
        } else if (row.type === "notice_row") {
          return <NoticeRow row={row} key={"notice" + index} />;
        } else {
          throw new Error(`Row type not supported: "${row.type}"`);
        }
      })}
    </div>
  );
};

const widestTimeType = (rows: Row[]): string => {
  const timeTypes = new Set<string>();

  const addTimeType = (type: string) => {
    if (!TIME_TYPE_PRIORITY.includes(type)) {
      throw new Error(`Unknown time type: "${type}"`);
    }

    timeTypes.add(type);
  };

  rows.forEach((row) => {
    if (row.type !== "departure_row") return;

    if (row.is_first_trip) {
      addTimeType("first");
      return;
    }

    (row.times_with_crowding ?? []).forEach((time) => {
      const type = time.time?.type;
      if (type === "minutes" && (time.time?.minutes ?? 0) >= 60) {
        // Require more space to show XhYYm format
        addTimeType("hours-and-minutes");
      } else if (type) {
        addTimeType(type);
      }
    });
  });

  return TIME_TYPE_PRIORITY.find((type) => timeTypes.has(type)) ?? "";
};

export default NormalSection;

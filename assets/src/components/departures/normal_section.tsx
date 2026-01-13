import type { ComponentType } from "react";
import weakKey from "weak-key";

import DepartureRow from "./departure_row";
import NoticeRow from "./notice_row";
import Header from "./header";
import LaterDepartures, { MIN_LATER_DEPARTURES } from "./later_departures";

export type Layout = {
  base: number | null;
  max: number | null;
  min: number;
  include_later: boolean;
};

export type Row =
  | (DepartureRow & { type: "departure_row" })
  | (NoticeRow & { type: "notice_row" });

export type NormalSection = {
  layout: Layout;
  header: Header;
  grouping_type: GroupingType;
  rows: Row[];
};

export interface BaseFoldedSection {
  type: "folded_section";
  layout: Layout;
  header: Header;
  grouping_type: GroupingType;
  rows: FoldedRows;
}

export interface FoldedDepartureGroupedSection extends BaseFoldedSection {
  grouping_type: "destination";
  direction_trim_priority: 0 | 1;
}

interface FoldedNormalSection extends BaseFoldedSection {
  grouping_type: "time";
}

export type FoldedSection = FoldedNormalSection | FoldedDepartureGroupedSection;

type GroupingType = "time" | "destination";

type FoldedRows = {
  aboveFold: Row[];
  belowFold: DepartureRow[];
};

const NormalSection: ComponentType<FoldedSection> = ({
  header,
  layout: { include_later: includeLater },
  grouping_type: groupingType,
  rows: { aboveFold, belowFold },
}) => {
  const rowToAddDivider = (aboveFold: Row[]) =>
    aboveFold.findIndex((row, index, arr) => {
      const nextRow = arr[index + 1];
      return (
        row &&
        nextRow &&
        row.type === "departure_row" &&
        nextRow.type === "departure_row" &&
        row.direction_id !== nextRow.direction_id
      );
    });

  return (
    <div className="departures-section">
      <Header {...header} />
      {aboveFold.map((row, index) => {
        if (row.type === "departure_row") {
          return (
            <DepartureRow
              {...row}
              key={row.id}
              isBeforeDirectionSplit={
                groupingType === "destination" &&
                index === rowToAddDivider(aboveFold)
              }
            />
          );
        } else {
          return <NoticeRow row={row} key={weakKey(row)} />;
        }
      })}

      {includeLater && belowFold.length >= MIN_LATER_DEPARTURES && (
        <LaterDepartures rows={belowFold} />
      )}
    </div>
  );
};

export default NormalSection;

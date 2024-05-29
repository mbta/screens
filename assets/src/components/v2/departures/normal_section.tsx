import React, { ComponentType } from "react";
import weakKey from "weak-key";

import DepartureRow from "./departure_row";
import NoticeRow from "./notice_row";
import Header from "./header";
import LaterDepatures from "./later_departures";

export type Layout = {
  base: number | null;
  max: number | null;
  min: number;
  include_later: boolean;
};

export type Row =
  | (DepartureRow & { type: "departure_row" })
  | (NoticeRow & { type: "notice_row" });

export interface NormalSection {
  layout: Layout;
  header: React.ComponentProps<typeof Header>;
  rows: Row[];
}

export interface NormalSectionWithLaterRows extends NormalSection {
  laterRows: DepartureRow[];
}

const NormalSection: ComponentType<NormalSectionWithLaterRows> = ({
  header,
  layout,
  rows,
  laterRows,
}) => {
  return (
    <div className="departures-section">
      <Header {...header} />
      {rows.map((row) => {
        if (row.type === "departure_row") {
          return <DepartureRow {...row} key={row.id} />;
        } else {
          return <NoticeRow row={row} key={weakKey(row)} />;
        }
      })}
      {layout.include_later && laterRows.length > 0 && (
        <LaterDepatures rows={laterRows} />
      )}
    </div>
  );
};

export default NormalSection;

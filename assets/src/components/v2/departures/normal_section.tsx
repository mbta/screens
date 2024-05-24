import React, { ComponentType } from "react";
import weakKey from "weak-key";

import DepartureRow from "./departure_row";
import NoticeRow from "./notice_row";
import Header from "./header";

export type Layout = {
  base: number | null;
  max: number | null;
  min: number;
};

export type Row =
  | (DepartureRow & { type: "departure_row" })
  | (NoticeRow & { type: "notice_row" });

type NormalSection = {
  layout: Layout;
  header: React.ComponentProps<typeof Header>;
  rows: Row[];
};

const NormalSection: ComponentType<NormalSection> = ({ rows, header }) => {
  return (
    <div>
      <div className="departures-section">
        <Header {...header} />
        {rows.map((row) => {
          if (row.type === "departure_row") {
            return <DepartureRow {...row} key={row.id} />;
          } else {
            return <NoticeRow row={row} key={weakKey(row)} />;
          }
        })}
      </div>
    </div>
  );
};

export default NormalSection;

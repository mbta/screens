import React, { ComponentType } from "react";
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
  rows: Row[];
};

export type FoldedNormalSection = {
  layout: Layout;
  header: Header;
  rows: FoldedRows;
};

type FoldedRows = {
  aboveFold: Row[];
  belowFold: DepartureRow[];
};

const NormalSection: ComponentType<FoldedNormalSection> = ({
  header,
  layout: { include_later: includeLater },
  rows: { aboveFold, belowFold },
}) => {
  return (
    <div className="departures-section">
      <Header {...header} />

      {aboveFold.map((row) => {
        if (row.type === "departure_row") {
          return <DepartureRow {...row} key={row.id} />;
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

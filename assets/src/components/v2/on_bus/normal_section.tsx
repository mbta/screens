import React, { ComponentType } from "react";

import DepartureRow from "./departure_row";
import useCurrentPage from "Hooks/use_current_dup_page";

export type NormalSectionProps = {
  rows: DepartureRow[];
};

export const NormalSection: ComponentType<NormalSectionProps> = ({ rows }) => {
  if (rows.length == 0) return null;

  const currentPage = useCurrentPage();

  return (
    <div className="departures-section">
      {rows.map((row, index) => {
        return <DepartureRow {...row} key={index} currentPage={currentPage} />;
      })}
    </div>
  );
};

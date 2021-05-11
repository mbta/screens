import React from "react";

import DepartureRow from "Components/v2/departures/departure_row";

const NormalSection = ({ rows }) => {
  return (
    <div className="departures-section">
      {rows.map((rowProps) => (
        <DepartureRow {...rowProps} key={JSON.stringify(rowProps)} />
      ))}
    </div>
  );
};

export default NormalSection;

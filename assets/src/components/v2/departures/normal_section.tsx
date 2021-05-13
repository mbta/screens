import React from "react";

import DepartureRow from "Components/v2/departures/departure_row";

const NormalSection = ({ rows }) => {
  return (
    <div className="departures-section">
      {rows.map((rowProps) => {
        const { id, ...data } = rowProps;
        return <DepartureRow {...data} key={id} />;
      })}
    </div>
  );
};

export default NormalSection;

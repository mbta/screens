import React, { forwardRef } from "react";
import DeparturesRow from "./departures_row";

const buildDeparturesRows = departures => {
  if (!departures) {
    return [];
  }

  const rows = [];

  // Do we need to do anything with inlineBadges?
  departures.forEach(row => {
    if (rows.length === 0) {
      const newRow = Object.assign({}, row);
      newRow.time = [newRow.time];
      rows.push(newRow);
    } else {
      const lastRow = rows[rows.length - 1];
      if (
        row.route === lastRow.route &&
        row.destination === lastRow.destination
      ) {
        lastRow.time.push(row.time);
      } else {
        const newRow = Object.assign({}, row);
        newRow.time = [newRow.time];
        rows.push(newRow);
      }
    }
  });

  return rows;
};

const Departures = forwardRef(
  (
    { currentTimeString, departures, startIndex, endIndex, size },
    ref
  ): JSX.Element => {
    let filteredRows;
    if (!departures) {
      filteredRows = departures;
    } else {
      filteredRows = departures.slice(startIndex, endIndex);
    }

    const rows = buildDeparturesRows(filteredRows);
    return (
      <div className="departures" ref={ref}>
        {rows.map((row, i) => (
          <DeparturesRow
            currentTimeString={currentTimeString}
            route={row.route}
            destination={row.destination}
            departureTimes={row.time}
            inlineBadges={row.inline_badges}
            size={size}
            key={row.route + row.time + i}
          />
        ))}
      </div>
    );
  }
);

export default Departures;

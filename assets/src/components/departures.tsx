import React, { forwardRef } from "react";
import DeparturesRow from "./departures_row";

const buildDeparturesRows = (
  departuresRows,
  alerts,
  departuresAlerts,
  numRows
) => {
  if (!departuresRows || !alerts || !departuresAlerts) {
    return [];
  }

  departuresRows = departuresRows.slice(0, numRows);

  const rows = [];
  departuresRows.forEach(row => {
    const rowAlerts = [];
    departuresAlerts.forEach(da => {
      const alertId = da[0];
      const departureId = da[1];

      if (row.id === departureId) {
        rowAlerts.push(alertId);
      }
    });

    if (rows.length === 0) {
      const newRow = Object.assign({}, row);
      newRow.time = [newRow.time];
      newRow.alerts = rowAlerts;
      rows.push(newRow);
    } else {
      const lastRow = rows[rows.length - 1];
      if (
        row.route === lastRow.route &&
        row.destination === lastRow.destination
      ) {
        lastRow.time.push(row.time);
        // Take union of rowAlerts?
      } else {
        const newRow = Object.assign({}, row);
        newRow.time = [newRow.time];
        newRow.alerts = rowAlerts;
        rows.push(newRow);
      }
    }
  });

  return rows;
};

const Departures = forwardRef(
  (
    {
      currentTimeString,
      departureRows,
      alerts,
      departuresAlerts,
      startIndex,
      endIndex,
      modifier
    },
    ref
  ): JSX.Element => {
    let filteredRows;
    if (!departureRows) {
      filteredRows = departureRows;
    } else {
      filteredRows = departureRows.slice(startIndex, endIndex);
    }
    const rows = buildDeparturesRows(
      filteredRows,
      alerts,
      departuresAlerts,
      endIndex - startIndex
    );

    let prefix;
    if (modifier) {
      prefix = "later-";
    } else {
      prefix = "";
    }

    return (
      <div className={prefix + "departures-container"} ref={ref}>
        {rows.map((row, i) => (
          <DeparturesRow
            currentTimeString={currentTimeString}
            route={row.route}
            destination={row.destination}
            departureTimes={row.time}
            rowAlerts={row.alerts}
            alerts={alerts}
            modifier={modifier}
            key={row.route + row.time + i}
          />
        ))}
      </div>
    );
  }
);

export default Departures;

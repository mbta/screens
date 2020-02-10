import moment from "moment";
import "moment-timezone";
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

const LaterDepartures = forwardRef(
  (
    {
      departureRows,
      startIndex,
      currentTime,
      alerts,
      departuresAlerts,
      bottomNumRows
    },
    ref
  ): JSX.Element => {
    if (!departureRows) {
      return <div></div>;
    }

    const laterDepartureRows = departureRows.slice(
      startIndex,
      startIndex + bottomNumRows
    );
    const rows = buildDeparturesRows(
      laterDepartureRows,
      alerts,
      departuresAlerts,
      bottomNumRows
    );

    return (
      <div className="later-departures-container" ref={ref}>
        {rows.map((row, i) => (
          <div key={row.route + row.time + i}>
            <DeparturesRow
              currentTime={currentTime}
              route={row.route}
              destination={row.destination}
              departureTimes={row.time}
              rowAlerts={row.alerts}
              alerts={alerts}
              modifier={true}
            />
          </div>
        ))}
      </div>
    );
  }
);

export default LaterDepartures;

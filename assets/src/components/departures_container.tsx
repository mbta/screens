import moment from "moment";
import "moment-timezone";
import React, { forwardRef } from "react";

import DepartureDestination from "./departure_destination";
import DepartureRoute from "./departure_route";
import DepartureTime from "./departure_time";
import DeparturesAlert from "./departures_alert";

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

const DeparturesContainer = forwardRef(
  (
    { currentTimeString, departureRows, alerts, departuresAlerts, numRows },
    ref
  ) => {
    const rows = buildDeparturesRows(
      departureRows,
      alerts,
      departuresAlerts,
      numRows
    );

    return (
      <div className="departures-container" ref={ref}>
        {rows.map((row, i) => (
          <DeparturesRow
            currentTimeString={currentTimeString}
            route={row.route}
            destination={row.destination}
            departureTimes={row.time}
            rowAlerts={row.alerts}
            alerts={alerts}
            key={row.route + row.time + i}
          />
        ))}
      </div>
    );
  }
);

const DeparturesRow = ({
  currentTimeString,
  route,
  destination,
  departureTimes,
  rowAlerts,
  alerts
}): JSX.Element => {
  return (
    <div className="departures-row">
      <div className="departure-row-before"></div>
      <div className="departures-row-container">
        {departureTimes.map((t, i) => (
          <DepartureRow
            currentTimeString={currentTimeString}
            route={i === 0 ? route : undefined}
            destination={i === 0 ? destination : undefined}
            time={t}
            first={i === 0}
            key={route + t + i}
          />
        ))}
        <DeparturesAlert
          rowAlerts={rowAlerts}
          alerts={alerts}
          modifier={false}
        />
      </div>
      <div className="departure-row-after"></div>
      <div className="departure-row-hairline"></div>
    </div>
  );
};

const DepartureRow = ({
  currentTimeString,
  route,
  destination,
  time,
  first
}): JSX.Element => {
  return (
    <div className="departure-row">
      <DepartureRoute route={route} modifier={false} />
      <DepartureDestination destination={destination} modifier={false} />
      <DepartureTime
        time={time}
        currentTimeString={currentTimeString}
        modifier={false}
      />
    </div>
  );
};

export default DeparturesContainer;

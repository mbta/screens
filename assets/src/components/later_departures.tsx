import moment from "moment";
import "moment-timezone";
import React, { forwardRef } from "react";

import DepartureDestination from "./departure_destination";
import DepartureRoute from "./departure_route";
import DepartureTime from "./departure_time";

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

const parseSeverity = severity => {
  let delayDescription;
  let delayMinutes;

  // Note that delay severities are assumed to be between 3 and 9, inclusive
  // Probably want to fail gracefully if that's not true

  if (severity >= 8) {
    delayDescription = "more than";
    delayMinutes = 30 * (severity - 7);
  } else {
    delayDescription = "up to";
    delayMinutes = 5 * (severity - 1);
  }

  return {
    delayDescription,
    delayMinutes
  };
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
            <LaterDeparturesRow
              currentTime={currentTime}
              route={row.route}
              destination={row.destination}
              departureTimes={row.time}
              rowAlerts={row.alerts}
              alerts={alerts}
            />
          </div>
        ))}
      </div>
    );
  }
);

const LaterDeparturesRow = ({
  currentTime,
  route,
  destination,
  departureTimes,
  rowAlerts,
  alerts
}): JSX.Element => {
  return (
    <div className="later-departures-row">
      <div className="later-departure-row-before"></div>
      <div className="later-departures-row-container">
        {departureTimes.map((t, i) => (
          <LaterDepartureRow
            route={i === 0 ? route : undefined}
            destination={i === 0 ? destination : undefined}
            time={t}
            currentTime={currentTime}
            first={i === 0}
            key={route + t + i}
          />
        ))}
        <LaterDeparturesAlert rowAlerts={rowAlerts} alerts={alerts} />
      </div>
      <div className="later-departure-row-after"></div>
      <div className="later-departure-row-hairline"></div>
    </div>
  );
};

const LaterDeparturesAlert = ({ rowAlerts, alerts }): JSX.Element => {
  let severity;
  rowAlerts.forEach(alertId => {
    alerts.forEach(alert => {
      if (alertId === alert.id && alert.effect === "delay") {
        severity = alert.severity;
      }
    });
  });

  if (severity === undefined) {
    return <div></div>;
  }

  const { delayDescription, delayMinutes } = parseSeverity(severity);

  return (
    <div className="later-departures-row-inline-badge-container">
      <span className="later-departures-row-inline-badge">
        <img className="alert-badge-icon" src="images/alert.svg" />
        Delays {delayDescription + " "}
        <span className="later-departures-row-inline-emphasis">
          {delayMinutes} minutes
        </span>
      </span>
    </div>
  );
};

const LaterDepartureRow = ({
  route,
  destination,
  time,
  currentTime,
  first
}): JSX.Element => {
  return (
    <div className="later-departure-row">
      <DepartureRoute route={route} modifier={true} />
      <DepartureDestination destination={destination} modifier={true} />
      <DepartureTime
        time={time}
        currentTimeString={currentTime}
        modifier={true}
      />
    </div>
  );
};

export default LaterDepartures;

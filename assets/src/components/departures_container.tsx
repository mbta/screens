import moment from "moment";
import "moment-timezone";
import React, { forwardRef } from "react";

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
        <DeparturesAlert rowAlerts={rowAlerts} alerts={alerts} />
      </div>
      <div className="departure-row-after"></div>
      <div className="departure-row-hairline"></div>
    </div>
  );
};

const DeparturesAlert = ({ rowAlerts, alerts }): JSX.Element => {
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
    <div className="departures-row-inline-badge-container">
      <span className="departures-row-inline-badge">
        <img className="alert-badge-icon" src="images/alert.svg" />
        Delays {delayDescription + " "}
        <span className="departures-row-inline-emphasis">
          {delayMinutes} minutes
        </span>
      </span>
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
      <DepartureRoute route={route} />
      <DepartureDestination destination={destination} />
      <DepartureTime time={time} currentTimeString={currentTimeString} />
    </div>
  );
};

const DepartureRoute = ({ route }): JSX.Element => {
  if (!route) {
    return <div className="departure-route"></div>;
  }

  let pillClass;
  let routeClass;
  if (route.includes("/")) {
    pillClass = "departure-route-pill departure-route-pill-small";
    routeClass = "departure-route-number departure-route-number-small";
  } else {
    pillClass = "departure-route-pill departure-route-pill-medium";
    routeClass = "departure-route-number departure-route-number-medium";
  }

  return (
    <div className="departure-route">
      <div className={pillClass}>
        <span className={routeClass}>{route}</span>
      </div>
    </div>
  );
};

const DepartureDestination = ({ destination }): JSX.Element => {
  if (destination === undefined) {
    return <div className="departure-destination"></div>;
  }

  if (destination.includes("via")) {
    const parts = destination.split(" via ");
    const primaryDestination = parts[0];
    const secondaryDestination = "via " + parts[1];

    return (
      <div className="departure-destination">
        <div className="departure-destination-container">
          <div className="departure-destination-primary">
            {primaryDestination}
          </div>
          <div className="departure-destination-secondary">
            {secondaryDestination}
          </div>
        </div>
      </div>
    );
  } else {
    return (
      <div className="departure-destination">
        <div className="departure-destination-container">
          <div className="departure-destination-primary">{destination}</div>
        </div>
      </div>
    );
  }
};

const DepartureTime = ({ time, currentTimeString }): JSX.Element => {
  const departureTime = moment(time);
  const currentTime = moment(currentTimeString);
  const secondDifference = departureTime.diff(currentTime, "seconds");
  const minuteDifference = Math.round(secondDifference / 60);

  if (secondDifference < 60) {
    return (
      <div className="departure-time">
        <span className="departure-time-now">Now</span>
      </div>
    );
  } else if (minuteDifference < 60) {
    return (
      <div className="departure-time">
        <span className="departure-time-minutes">{minuteDifference}</span>
        <span className="departure-time-minutes-label">m</span>
      </div>
    );
  } else {
    const timestamp = departureTime.format("h:mm");
    const ampm = departureTime.format("A");
    return (
      <div className="departure-time">
        <span className="departure-time-timestamp">{timestamp}</span>
        <span className="departure-time-ampm">{ampm}</span>
      </div>
    );
  }
};

export default DeparturesContainer;

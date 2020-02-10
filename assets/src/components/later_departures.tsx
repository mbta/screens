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
      <LaterDepartureRoute route={route} />
      <LaterDepartureDestination destination={destination} />
      <LaterDepartureTime time={time} currentTimeString={currentTime} />
    </div>
  );
};

const LaterDepartureRoute = ({ route }): JSX.Element => {
  if (!route) {
    return <div className="later-departure-route"></div>;
  }

  let pillClass;
  let routeClass;
  if (route.includes("/")) {
    pillClass = "later-departure-route-pill later-departure-route-pill-small";
    routeClass =
      "later-departure-route-number later-departure-route-number-small";
  } else {
    pillClass = "later-departure-route-pill later-departure-route-pill-medium";
    routeClass =
      "later-departure-route-number later-departure-route-number-medium";
  }

  return (
    <div className="later-departure-route">
      <div className={pillClass}>
        <span className={routeClass}>{route}</span>
      </div>
    </div>
  );
};

const LaterDepartureDestination = ({ destination }): JSX.Element => {
  if (destination === undefined) {
    return <div className="later-departure-destination"></div>;
  }

  if (destination.includes("via")) {
    const parts = destination.split(" via ");
    const primaryDestination = parts[0];
    const secondaryDestination = "via " + parts[1];

    return (
      <div className="later-departure-destination">
        <div className="later-departure-destination-container">
          <div className="later-departure-destination-primary">
            {primaryDestination}
          </div>
          <div className="later-departure-destination-secondary">
            {secondaryDestination}
          </div>
        </div>
      </div>
    );
  } else {
    return (
      <div className="later-departure-destination">
        <div className="later-departure-destination-container">
          <div className="later-departure-destination-primary">
            {destination}
          </div>
        </div>
      </div>
    );
  }
};

const LaterDepartureTime = ({ time, currentTimeString }): JSX.Element => {
  const departureTime = moment(time);
  const currentTime = moment(currentTime);
  const secondDifference = departureTime.diff(currentTime, "seconds");
  const minuteDifference = Math.round(secondDifference / 60);

  if (secondDifference < 60) {
    return (
      <div className="later-departure-time-container">
        <span className="later-departure-time-now">Now</span>
      </div>
    );
  } else if (minuteDifference < 60) {
    return (
      <div className="later-departure-time-container">
        <span className="later-departure-time-minutes">{minuteDifference}</span>
        <span className="later-departure-time-minutes-label">m</span>
      </div>
    );
  } else {
    const timestamp = departureTime.tz("America/New_York").format("h:mm");
    const ampm = departureTime.tz("America/New_York").format("A");

    return (
      <div className="later-departure-time-container">
        <span className="later-departure-time-timestamp">{timestamp}</span>
        <span className="later-departure-time-ampm">{ampm}</span>
      </div>
    );
  }
};

export default LaterDepartures;

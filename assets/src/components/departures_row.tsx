import React from "react";

import DepartureRow from "./departure_row";
import DeparturesAlert from "./departures_alert";

const DeparturesRow = ({
  currentTime,
  route,
  destination,
  departureTimes,
  rowAlerts,
  alerts,
  modifier
}): JSX.Element => {
  let prefix;
  if (modifier) {
    prefix = "later-";
  } else {
    prefix = "";
  }

  return (
    <div className={prefix + "departures-row"}>
      <div className={prefix + "departure-row-before"}></div>
      <div className={prefix + "departures-row-container"}>
        {departureTimes.map((t, i) => (
          <DepartureRow
            currentTime={currentTime}
            route={i === 0 ? route : undefined}
            destination={i === 0 ? destination : undefined}
            time={t}
            first={i === 0}
            modifier={modifier}
            key={route + t + i}
          />
        ))}
        <DeparturesAlert
          rowAlerts={rowAlerts}
          alerts={alerts}
          modifier={modifier}
        />
      </div>
      <div className={prefix + "departure-row-after"}></div>
      <div className={prefix + "departure-row-hairline"}></div>
    </div>
  );
};

export default DeparturesRow;

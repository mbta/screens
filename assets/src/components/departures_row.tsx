import React from "react";

import { classWithSize } from "../util";
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

  const size = modifier ? "small" : "large";

  return (
    <div className="departures-row">
      <div className={classWithSize("departures-row__before", size)}></div>
      <div className="departures-row__container">
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
      <div className={classWithSize("departures-row__after", size)}></div>
      <div className="departures-row__hairline"></div>
    </div>
  );
};

export default DeparturesRow;

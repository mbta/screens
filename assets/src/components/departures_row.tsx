import React from "react";

import { classWithSize } from "../util";
import DepartureRow from "./departure_row";
import InlineAlert from "./inline_alert";

const DeparturesRow = ({
  currentTimeString,
  route,
  destination,
  departureTimes,
  inlineBadges,
  size
}): JSX.Element => {
  return (
    <div className="departures-row">
      <div className={classWithSize("departures-row__container", size)}>
        {departureTimes.map((t, i) => (
          <DepartureRow
            currentTimeString={currentTimeString}
            route={i === 0 ? route : undefined}
            destination={i === 0 ? destination : undefined}
            time={t}
            size={size}
            key={route + t + i}
          />
        ))}
        <InlineAlert inlineBadges={inlineBadges} />
      </div>
      <div className="departures-row__hairline"></div>
    </div>
  );
};

export default DeparturesRow;

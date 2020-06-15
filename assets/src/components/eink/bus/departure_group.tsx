import React from "react";

import DepartureRow from "Components/eink/bus/departure_row";
import InlineAlert from "Components/eink/bus/inline_alert";
import { classWithModifier } from "Util/util";

const DepartureGroup = ({
  currentTimeString,
  departures,
  size,
}): JSX.Element => {
  return (
    <div className="departure-group">
      <div className={classWithModifier("departure-group__container", size)}>
        {departures.map(
          (
            { id, route, destination, crowding_level: crowdingLevel, time },
            i
          ) => (
            <DepartureRow
              currentTimeString={currentTimeString}
              route={i === 0 ? route : null}
              destination={i === 0 ? destination : null}
              crowdingLevel={crowdingLevel}
              time={time}
              size={size}
              key={id}
            />
          )
        )}
        <InlineAlert inlineBadges={departures[0].inlineBadges} />
      </div>
      <div className="departure-group__hairline"></div>
    </div>
  );
};

export default DepartureGroup;

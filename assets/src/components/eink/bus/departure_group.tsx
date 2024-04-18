import React from "react";

import DepartureRow from "Components/eink/bus/departure_row";
import InlineAlert from "Components/eink/bus/inline_alert";
import { classWithModifier } from "Util/util";

type Props = {
  currentTimeString: string
  departures: object[]
  size: string
}

const DepartureGroup = ({
  currentTimeString,
  departures,
  size,
}): JSX.Element => {
  const alerts = departures[0].alerts;

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
        {alerts && alerts.length > 0 && <InlineAlert />}
      </div>
      <div className="departure-group__hairline"></div>
    </div>
  );
};

export { Props };
export default DepartureGroup;

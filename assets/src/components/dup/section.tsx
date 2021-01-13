import React from "react";

import Departure from "Components/dup/departure";
import FreeText from "Components/dup/free_text";

const camelizeDepartureObject = ({
  id,
  route,
  destination,
  time,
  scheduled_time: scheduledTime,
  route_id: routeId,
  vehicle_status: vehicleStatus,
  alerts,
  stop_type: stopType,
  crowding_level: crowdingLevel,
}) => ({
  id,
  route,
  destination,
  time,
  scheduledTime,
  routeId,
  vehicleStatus,
  alerts,
  stopType,
  crowdingLevel,
});

const Section = ({ departures, currentTimeString }): JSX.Element => {
  return (
    <div className="section">
      {departures.map((departure) => (
        <Departure
          {...camelizeDepartureObject(departure)}
          currentTimeString={currentTimeString}
          key={departure.id}
        />
      ))}
      <div className="section-hairline" />
    </div>
  );
};

const HeadwaySection = ({ headway, pill }): JSX.Element => {
  const [lo, hi] = headway;
  const lines = {
    icon: pill,
    text: ["every", { format: "bold", text: `${lo}-${hi}` }, "minutes"],
  };
  return (
    <div className="section section--headway">
      <div className="partial-alert partial-alert--dark">
        <FreeText lines={lines} />
      </div>
    </div>
  );
};

export default Section;
export { HeadwaySection };

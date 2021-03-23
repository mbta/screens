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
  track_number: trackNumber,
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
  trackNumber,
});

const Section = ({
  departures,
  currentTimeString,
  currentPage,
}): JSX.Element => {
  return (
    <div className="section">
      {departures.map((departure) => (
        <Departure
          {...camelizeDepartureObject(departure)}
          currentTimeString={currentTimeString}
          currentPage={currentPage}
          key={departure.id}
        />
      ))}
      <div className="section-hairline" />
    </div>
  );
};

const HeadwaySection = ({ headway, pill }): JSX.Element => {
  return (
    <div className="section section--headway">
      <div className="partial-alert partial-alert--dark">
        <FreeText lines={headway} />
      </div>
    </div>
  );
};

export default Section;
export { HeadwaySection };

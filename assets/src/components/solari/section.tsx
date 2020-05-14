import React from "react";

import Departure from "Components/solari/departure";
import Arrow from "Components/solari/arrow";

const SectionHeader = ({ name, arrow }): JSX.Element => {
  return (
    <div className="section-header">
      <span className="section-header__name">{name}</span>
      <span className="section-header__arrow-container">
        {arrow !== null && (
          <Arrow direction={arrow} className="section-header__arrow-image" />
        )}
      </span>
    </div>
  );
};

const Section = ({
  name,
  arrow,
  departures,
  currentTimeString,
}): JSX.Element => {
  return (
    <div className="section">
      <SectionHeader name={name} arrow={arrow} />
      <div className="departure-container">
        {departures.map(({
            id,
            route,
            destination,
            time,
            route_id: routeId,
            vehicle_status: vehicleStatus,
            alerts
          }) => {
          return (
            <Departure
              route={route}
              routeId={routeId}
              destination={destination}
              time={time}
              currentTimeString={currentTimeString}
              vehicleStatus={vehicleStatus}
              alerts={alerts}
              key={id}
            />
          );
        })}
      </div>
    </div>
  );
};

export default Section;

import React from "react";

import Departure from "Components/solari/departure";
import Arrow from "Components/solari/arrow";

const SectionHeader = ({ name, arrow }): JSX.Element => {
  return (
    <div className="section-header">
      <span className="section-header__arrow-container">
        {arrow !== null && (
          <Arrow direction={arrow} className="section-header__arrow-image" />
        )}
      </span>
      <span className="section-header__name">{name}</span>
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
        {departures.map((departure) => {
          const { id, route, destination, time } = departure;
          const routeId = departure.route_id;
          return (
            <Departure
              route={route}
              routeId={routeId}
              destination={destination}
              time={time}
              currentTimeString={currentTimeString}
              key={id}
            />
          );
        })}
      </div>
    </div>
  );
};

export default Section;

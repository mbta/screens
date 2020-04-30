import React from "react";

import Departure from "Components/solari/departure";

const SectionHeader = ({ name, arrow }): JSX.Element => {
  return (
    <div className="section-header">
      <span className="section-header__arrow">{arrow}</span>
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
    <div className="section-list">
      <SectionHeader name={name} arrow={arrow} />
      <div className="departure-container">
        {departures.map(({ id, route, destination, time }) => (
          <Departure
            route={route}
            destination={destination}
            time={time}
            currentTimeString={currentTimeString}
            key={id}
          />
        ))}
      </div>
    </div>
  );
};

export default Section;

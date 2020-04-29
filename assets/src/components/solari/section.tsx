import React from "react";

const SectionHeader = ({name, arrow}): JSX.Element => {
  return (
    <div className="section-header">
      <span className="section-header__arrow">{arrow}</span>
      <span className="section-header__name">{name}</span>
    </div>
  )
}

const Section = ({name, arrow, departures, currentTimeString}): JSX.Element => {
  return (

    <div className="section-list">
      <SectionHeader name={name} arrow={arrow} />
      {departures.map(({route, destination, time}) => (
        <Departure
          id={id}
          route={route}
          destination={destination}
          directionId={direction_id}
          time={time}
          inlineBadges={inline_badges}
          currentTimeString={currentTimeString}
          key={id}
        />
      ))}
    </div>
  );
};

export default Section;

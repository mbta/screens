import DeparturesRow from "Components/eink/bus/departures_row";
import React, { forwardRef } from "react";

const buildDepartureGroups = (departures) => {
  if (!departures) {
    return [];
  }

  const groups = [];

  departures.forEach((departure) => {
    if (groups.length === 0) {
      groups.push([departure]);
    } else {
      const currentGroup = groups[groups.length - 1];
      const {
        route: groupRoute,
        destination: groupDestination,
      } = currentGroup[0];
      const {
        route: departureRoute,
        destination: departureDestination,
      } = departure;
      if (
        groupRoute === departureRoute &&
        groupDestination === departureDestination
      ) {
        currentGroup.push(departure);
      } else {
        groups.push([departure]);
      }
    }
  });

  return groups;
};

const Departures = forwardRef(
  ({ currentTimeString, departures, size }, ref): JSX.Element => {
    if (!departures || departures.length === 0) {
      return null;
    }
    const departureGroups = buildDepartureGroups(departures);
    return (
      <div className="departures" ref={ref}>
        {departureGroups.map((group, i) => (
          <DeparturesRow
            currentTimeString={currentTimeString}
            departures={group}
            size={size}
            key={group[0].id}
          />
        ))}
      </div>
    );
  }
);

export default Departures;

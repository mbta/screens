import { useLayoutEffect, useState } from "react";

const useFitDepartures = (departuresRef, laterDeparturesRef) => {
  // Fit as many rows as will fit in departures and later departures
  const MAX_DEPARTURE_ROWS = 7;
  const MAX_LATER_DEPARTURE_ROWS = 5;
  const MAX_DEPARTURES_HEIGHT = 1312;
  const MAX_LATER_DEPARTURES_HEIGHT = 585;

  const [departureCount, setDepartureCount] = useState(MAX_DEPARTURE_ROWS);
  const [laterDepartureCount, setLaterDepartureCount] = useState(
    MAX_LATER_DEPARTURE_ROWS
  );

  useLayoutEffect(() => {
    if (departuresRef.current) {
      const departuresHeight = departuresRef.current.clientHeight;
      if (departuresHeight > MAX_DEPARTURES_HEIGHT) {
        setDepartureCount(departureCount - 1);
      }
    }

    if (laterDeparturesRef.current) {
      const laterDeparturesHeight = laterDeparturesRef.current.clientHeight;
      if (laterDeparturesHeight > MAX_LATER_DEPARTURES_HEIGHT) {
        setLaterDepartureCount(laterDepartureCount - 1);
      }
    }
  });

  return { departureCount, laterDepartureCount };
};

export default useFitDepartures;

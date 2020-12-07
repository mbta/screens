import React, { useState, useEffect } from "react";

import {
  standardTimeRepresentation,
  timeRepresentationsEqual,
} from "Util/time_representation";

import { classWithModifier } from "Util/util";

import BaseDepartureTime from "Components/eink/base_departure_time";

const Time = ({
  time,
  scheduledTime,
  currentTimeString,
  vehicleStatus,
  stopType,
  noMinutes,
}) => {
  const [page, setPage] = useState(0);

  useEffect(() => {
    const interval = setInterval(() => {
      setPage((p) => 1 - p);
    }, 3750);
    return () => clearInterval(interval);
  }, []);

  const timeRepresentation = standardTimeRepresentation(
    time,
    currentTimeString,
    vehicleStatus,
    stopType,
    noMinutes,
    false
  );

  if (scheduledTime && timeRepresentation.type !== "TEXT") {
    const scheduleRepresentation = standardTimeRepresentation(
      scheduledTime,
      currentTimeString,
      vehicleStatus,
      stopType,
      noMinutes,
      true
    );
    if (!timeRepresentationsEqual(timeRepresentation, scheduleRepresentation)) {
      if (page === 0) {
        return (
          <div className="departure-time">
            <BaseDepartureTime time={timeRepresentation} hideAmPm={true} />
          </div>
        );
      } else {
        return (
          <div className={classWithModifier("departure-time", "disabled")}>
            <BaseDepartureTime time={scheduleRepresentation} hideAmPm={true} />
          </div>
        );
      }
    }
  }

  return (
    <div className="departure-time">
      <BaseDepartureTime time={timeRepresentation} hideAmPm={true} />
    </div>
  );
};

export default Time;

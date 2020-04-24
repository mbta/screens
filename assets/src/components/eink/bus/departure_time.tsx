import React from "react";

import BaseDepartureTime from "Components/eink/base_departure_time";
import { classWithModifier } from "Util";

const DepartureTime = ({ time, currentTimeString, size }): JSX.Element => {
  return (
    <div className={classWithModifier("departure-time", size)}>
      <BaseDepartureTime
        departureTimeString={time}
        currentTimeString={currentTimeString}
      />
    </div>
  );
};

export default DepartureTime;

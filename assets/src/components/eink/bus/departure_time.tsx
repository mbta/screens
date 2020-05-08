import {einkTimeRepresentation} from "Util/time_representation";

import React from "react";

import BaseDepartureTime from "Components/eink/base_departure_time";
import { classWithModifier } from "Util/util";

const DepartureTime = ({ time, currentTimeString, size }): JSX.Element => {
  return (
    <div className={classWithModifier("departure-time", size)}>
      <BaseDepartureTime
        time={einkTimeRepresentation(time, currentTimeString)}
      />
    </div>
  );
};

export default DepartureTime;

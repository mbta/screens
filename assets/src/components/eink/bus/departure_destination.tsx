import React from "react";

import { classWithModifier } from "Util/util";
import BaseDepartureDestination from "Components/eink/base_departure_destination";

const DepartureDestination = ({ destination, size }): JSX.Element => {
  return (
    <div className={classWithModifier("departure-destination", size)}>
      <BaseDepartureDestination destination={destination} />
    </div>
  );
};

export default DepartureDestination;

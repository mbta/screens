import React from "react";

import { classWithSize } from "Util";
import BaseDepartureDestination from "Components/eink/base_departure_destination";

const DepartureDestination = ({ destination, size }): JSX.Element => {
  return (
    <div className={classWithSize("departure-destination", size)}>
      <BaseDepartureDestination destination={destination} />
    </div>
  );
};

export default DepartureDestination;

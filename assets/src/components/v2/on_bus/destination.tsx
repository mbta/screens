import React, { ComponentType } from "react";

type Destination = {
  headsign: string;
};

const Destination: ComponentType<Destination> = ({ headsign }) => {
  return (
    <div className="departure-destination">
      <div className="departure-destination__headsign">{headsign}</div>
    </div>
  );
};

export default Destination;

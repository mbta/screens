import React, { ComponentType } from "react";

type Destination = {
  headsign: string;
  variation?: string;
};

const Destination: ComponentType<Destination> = ({ headsign, variation }) => {
  return (
    <div className="departure-destination">
      <div className="departure-destination__headsign">{headsign}</div>
      {variation && (
        <div className="departure-destination__variation">{variation}</div>
      )}
    </div>
  );
};

export default Destination;

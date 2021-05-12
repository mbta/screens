import React from "react";

const Destination = ({ headsign, variation }) => {
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

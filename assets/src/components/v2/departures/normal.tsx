import React from "react";

interface Props {
  departures: object[];
}

const Row = ({ route, destination, time }) => {
  return (
    <div className="normal-departures-row">
      <div className="normal-departures-row__route">{route}</div>
      <div className="normal-departures-row__destination">{destination}</div>
      <div className="normal-departures-row__time">{time}</div>
    </div>
  );
};

const NormalDepartures: React.ComponentType<Props> = ({ departures }) => {
  return (
    <div className="normal-departures">
      {departures.map((d) => (
        <Row {...d} key={d.id} />
      ))}
    </div>
  );
};

export default NormalDepartures;

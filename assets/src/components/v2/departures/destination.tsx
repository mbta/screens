import type { ComponentType } from "react";

const abbreviate = (headsign: string): string => {
  if (headsign === "Government Center") return "Government Ctr";
  return headsign;
};

type Destination = {
  headsign: string;
  variation?: string;
};

const Destination: ComponentType<Destination> = ({ headsign, variation }) => {
  return (
    <div className="departure-destination">
      <div className="departure-destination__headsign">
        {abbreviate(headsign)}
      </div>
      {variation && (
        <div className="departure-destination__variation">{variation}</div>
      )}
    </div>
  );
};

export default Destination;

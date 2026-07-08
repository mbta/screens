import type { ComponentType } from "react";

import useAutoSize from "Hooks/use_auto_size";

type Destination = {
  headsigns: string[];
  variation?: string;
};

const Destination: ComponentType<Destination> = ({ headsigns, variation }) => {
  const { ref, step: headsign } = useAutoSize(headsigns);

  return (
    <div className="departure-destination">
      <div className="departure-destination__headsign" ref={ref}>
        {headsign}
      </div>
      {variation && (
        <div className="departure-destination__variation">{variation}</div>
      )}
    </div>
  );
};

export default Destination;

import type { ComponentType } from "react";

import { useHorizontalAutoSize } from "Hooks/use_auto_size";

type Destination = {
  headsigns: string[];
  variation?: string;
};

const Destination: ComponentType<Destination> = ({ headsigns, variation }) => {
  const { ref, step: sizedHeadsign } = useHorizontalAutoSize(headsigns);

  return (
    <div className="departure-destination">
      <div className="departure-destination__headsign" ref={ref}>
        {sizedHeadsign}
      </div>
      {variation && (
        <div className="departure-destination__variation">{variation}</div>
      )}
    </div>
  );
};

export default Destination;

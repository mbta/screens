import type { ComponentType } from "react";

import { useHorizontalAutoSize } from "Hooks/use_auto_size";

type Destination = {
  headsign?: string;
  headsigns?: string[];
  variation?: string;
};

const Destination: ComponentType<Destination> = ({ headsign, headsigns, variation }) => {
 if (!headsigns) {
  // We always receive either a list of headsign options or a single headsign
  headsigns = [headsign];
 }
 
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

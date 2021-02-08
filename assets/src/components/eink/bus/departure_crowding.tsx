import React from "react";
import { imagePath } from "Util/util";

const DepartureCrowding = ({ crowdingLevel }): JSX.Element => {
  return (
    <div className="departure-crowding">
      {crowdingLevel && (
        <img src={imagePath(`crowding-level-${crowdingLevel}.svg`)} />
      )}
    </div>
  );
};

export default DepartureCrowding;

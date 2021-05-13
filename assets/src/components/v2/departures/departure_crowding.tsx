import React from "react";

import { imagePath } from "Util/util";

const DepartureCrowding = ({ crowdingLevel }) => {
  const imgSrc = imagePath(`crowding-color-level-${crowdingLevel}.svg`);

  return (
    <div className="departure-crowding">
      <img className="departure-crowding__icon" src={imgSrc} />
    </div>
  );
};

export default DepartureCrowding;

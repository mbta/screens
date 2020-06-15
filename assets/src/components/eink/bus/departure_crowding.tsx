import React from "react";

const DepartureCrowding = ({ crowdingLevel }): JSX.Element => {
  return (
    <div className="departure-crowding">
      {crowdingLevel && (
        <img src={`/images/crowding-level-${crowdingLevel}.svg`} />
      )}
    </div>
  );
};

export default DepartureCrowding;

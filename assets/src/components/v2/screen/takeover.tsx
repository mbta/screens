import React from "react";

import Widget from "Components/v2/widget";

const Takeover = ({ fullscreen }) => {
  return (
    <div className="screen-takeover">
      <div className="screen-takeover__fullscreen">
        <Widget data={fullscreen} />
      </div>
    </div>
  );
};

export default Takeover;

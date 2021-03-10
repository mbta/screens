import React from "react";

import Widget from "Components/v2/widget";

const OneLarge = ({ large }) => {
  return (
    <div className="flex-one-large">
      <div className="flex-one-large__large">
        <Widget data={large} />
      </div>
    </div>
  );
};

export default OneLarge;

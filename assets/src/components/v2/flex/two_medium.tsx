import React from "react";

import Widget from "Components/v2/widget";

const TwoMedium = ({ medium_left: mediumLeft, medium_right: mediumRight }) => {
  return (
    <div className="flex-two-medium">
      <div className="flex-two-medium__left">
        <Widget data={mediumLeft} />
      </div>
      <div className="flex-two-medium__right">
        <Widget data={mediumRight} />
      </div>
    </div>
  );
};

export default TwoMedium;

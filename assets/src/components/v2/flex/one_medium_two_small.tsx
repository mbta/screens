import React from "react";

import Widget from "Components/v2/widget";

const OneMediumTwoSmall = ({
  medium_left: mediumLeft,
  small_upper_right: smallUpperRight,
  small_lower_right: smallLowerRight,
}) => {
  return (
    <div className="flex-one-medium-two-small">
      <div className="flex-one-medium-two-small__left">
        <Widget data={mediumLeft} />
      </div>
      <div className="flex-one-medium-two-small__right">
        <div className="flex-one-medium-two-small__upper-right">
          <Widget data={smallUpperRight} />
        </div>
        <div className="flex-one-medium-two-small__lower-right">
          <Widget data={smallLowerRight} />
        </div>
      </div>
    </div>
  );
};

export default OneMediumTwoSmall;

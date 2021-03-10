import React from "react";

import Normal from "Components/v2/screen/normal";
import Takeover from "Components/v2/screen/takeover";
import OneLarge from "Components/v2/flex/one_large";
import TwoMedium from "Components/v2/flex/two_medium";
import OneMediumTwoSmall from "Components/v2/flex/one_medium_two_small";

const TYPE_TO_COMPONENT = {
  normal: Normal,
  takeover: Takeover,
  one_large: OneLarge,
  two_medium: TwoMedium,
  one_medium_two_small: OneMediumTwoSmall,
};

const Widget = ({ data }) => {
  const { type, ...props } = data;
  const Component = TYPE_TO_COMPONENT[type];

  if (Component) {
    return <Component {...props} />;
  }

  return <>{type}</>;
};

export default Widget;

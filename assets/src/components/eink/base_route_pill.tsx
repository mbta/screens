import React from "react";

import { classWithModifier } from "Util";

const BaseRoutePill = ({ route }): JSX.Element => {
  const modifier = route.includes("/") ? "with-slash" : "no-slash";

  return (
    <div className={classWithModifier("base-route-pill__pill", modifier)}>
      <div
        className={classWithModifier("base-route-pill__route-text", modifier)}
      >
        {route}
      </div>
    </div>
  );
};

export default BaseRoutePill;

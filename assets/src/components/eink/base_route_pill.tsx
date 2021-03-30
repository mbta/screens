import React from "react";

import { classWithModifier } from "Util/util";

const BaseRoutePill = ({ route }): JSX.Element => {
  const isSlashRoute = typeof route === "string" && route.includes("/");

  const modifier =
    isSlashRoute
      ? "with-slash"
      : "no-slash";

  if (isSlashRoute) {
    const parts = route.split("/");
    const part1 = parts[0] + "/";
    const part2 = parts[1];

    return (
      <div className={classWithModifier("base-route-pill__pill", modifier)}>
        <div
          className={classWithModifier("base-route-pill__route-text", modifier)}
        >
          <div className="base-route-pill__route-text--with-slash__part1">{part1}</div>
          <div className="base-route-pill__route-text--with-slash__part2">{part2}</div>
        </div>
      </div>
    );
  }

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

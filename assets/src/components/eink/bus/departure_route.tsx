import React from "react";

import { classWithModifier } from "Util/util";
import BaseRoutePill from "Components/eink/base_route_pill";

const DepartureRoute = ({ route, size }): JSX.Element => {
  if (!route) {
    return <div className={classWithModifier("departure-route", size)}></div>;
  }

  return (
    <div className={classWithModifier("departure-route", size)}>
      <BaseRoutePill route={route} />
    </div>
  );
};

export default DepartureRoute;

import React from "react";

import { classWithModifier } from "Util/util";

interface Props {
  alert: {alert_header: string};
}

const ReconstructedAlert: React.ComponentType<Props> = (alert) => {
  return <div className={classWithModifier("placeholder", "orange")}>
    <div style={{fontSize: "36px", fontFamily: "sans-serif", padding: "24px"}}>{alert.alert_header}</div>
  </div>;
};

export default ReconstructedAlert;

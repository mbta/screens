import React from "react";

import FreeText from "Components/dup/free_text";
import { classWithModifier } from "Util/util";

const PartialAlert = ({ alert }) => {
  const { color, content } = alert;

  return (
    <div className={classWithModifier("partial-alert", color)}>
      <FreeText lines={content} />
    </div>
  );
};

const PartialAlerts = ({ alerts }) => {
  return (
    <div className="partial-alerts">
      <PartialAlert alert={alerts[0]} />
    </div>
  );
};

export default PartialAlerts;

import React from "react";

import { classWithModifier } from "Util/util";
import FreeText, { FreeTextType } from "./dup_free_text";

interface PartialAlertProps {
  text: FreeTextType,
  color: string
}

const PartialAlert = (alert: PartialAlertProps) => {
  const {text, color} = alert
  
  return (
    <div className={classWithModifier("partial-alert", color)}>
      <FreeText lines={text} />
    </div>
  );
};

export default PartialAlert;

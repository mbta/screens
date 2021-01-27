import React from "react";
import { imagePath } from "Util/util";

const InlineAlert = (): JSX.Element => {
  return (
    <div className="inline-alert">
      <div className="inline-alert__badge">
        <img className="inline-alert__icon" src={imagePath("alert.svg")} />
        <div className="inline-alert__text">Delays</div>
      </div>
    </div>
  );
};

export default InlineAlert;

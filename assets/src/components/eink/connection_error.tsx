import React from "react";
import { imagePath } from "Util/util";

const ConnectionError = (): JSX.Element => {
  return (
    <div className="connection-error">
      <img src={imagePath("no-data-static-single.png")} />
    </div>
  );
};

export default ConnectionError;

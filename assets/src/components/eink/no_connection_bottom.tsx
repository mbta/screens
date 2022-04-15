import React from "react";
import { imagePath } from "Util/util";

const NoConnectionBottom = (): JSX.Element => {
  return (
    <div className="connection-error">
      <img src={imagePath("no-data-static-bottom.png")} />
    </div>
  );
};

export default NoConnectionBottom;

import React from "react";
import { imagePath } from "Util/util";

const NoConnectionTop = (): JSX.Element => {
  return (
    <div className="connection-error">
      <img src={imagePath("no-data-static-top.png")} />
    </div>
  );
};

export default NoConnectionTop;

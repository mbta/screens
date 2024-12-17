import React, { ComponentType } from "react";
import { imagePath } from "Util/util";

const NoData: ComponentType = () => {
  return (
    <>
      <img src={imagePath(`elevator-status-no-data.png`)} />
    </>
  );
};

export default NoData;

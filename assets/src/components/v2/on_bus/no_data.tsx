import React, { ComponentType } from "react";
import Placeholder from "../placeholder";

const NoData: ComponentType = () => {
  return (
    <>
      <Placeholder color={"blue"} text={""} />
    </>
  );
};

export default NoData;

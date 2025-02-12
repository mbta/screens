import React, { ComponentType } from "react";
import Placeholder from "../placeholder";

// Fix station name tags without rider-facing names

const NoData: ComponentType = () => {
  return (
    <>
      <Placeholder color={"blue"} text={""} />
    </>
  );
};

export default NoData;

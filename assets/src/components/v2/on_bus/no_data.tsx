import React, { ComponentType } from "react";
import Placeholder from "../placeholder";

interface NoData {
  text: string;
}

const NoData: ComponentType = () => {
  return <Placeholder color="blue" text="No Data" />;
};

export default NoData;

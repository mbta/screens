import React from "react";

import { classWithModifier } from "Util/utils";

interface Props {
  color: string;
}

const Placeholder: React.ComponentType<Props> = ({ color }) => {
  console.log(classWithModifier("placeholder", color));
  return <div className={classWithModifier("placeholder", color)}></div>;
};

export default Placeholder;

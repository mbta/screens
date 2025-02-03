import React from "react";

import { classWithModifier } from "Util/utils";

interface Props {
  color: string;
}

const Placeholder: React.ComponentType<Props> = ({ color }) => {
  return <div className={classWithModifier("placeholder", color)}></div>;
};

export default Placeholder;

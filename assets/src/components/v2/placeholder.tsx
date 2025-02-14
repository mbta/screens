import React from "react";

import { classWithModifier } from "Util/utils";

interface Props {
  color: string;
  text: string;
}

const Placeholder: React.ComponentType<Props> = ({ color, text }) => {
  return (
    <div className={classWithModifier("placeholder", color)}>
      <div className="placeholder-text">
        <h3>{text}</h3>
      </div>
    </div>
  );
};

export default Placeholder;

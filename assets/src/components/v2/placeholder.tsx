import type { ComponentType } from "react";
import { classWithModifier } from "Util/utils";

interface Props {
  color: string;
  text?: string;
}

const Placeholder: ComponentType<Props> = ({ color, text }) => {
  return (
    <div className={classWithModifier("placeholder", color)}>
      <div className="placeholder__text">
        <h1>Test Mode</h1>
        <h3>{text}</h3>
      </div>
    </div>
  );
};

export default Placeholder;

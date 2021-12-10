import React, { ComponentType } from "react";

import DefaultNormalHeader from "Components/v2/normal_header";

interface Props {
  icon: Icon;
  text: string;
  time: string;
  show_to: boolean;
}

type Icon =
  | "logo"
  | "x"
  | "green_b"
  | "green_c"
  | "green_d"
  | "green_e";

const NormalHeader: ComponentType<Props> = ({ icon, text, time, show_to: showTo }) => {
  return (
    <DefaultNormalHeader
      icon={icon}
      text={text}
      time={time}
      showUpdated={true}
      maxHeight={208}
      showTo={showTo}
    />
  );
};

export default NormalHeader;

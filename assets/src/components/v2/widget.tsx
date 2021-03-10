import React from "react";

import NormalHeader from "Components/v2/header/normal";

const TYPE_TO_COMPONENT: Record<string, React.ComponentType<any>> = {
  normal_header: NormalHeader,
};

const Widget = ({ data }) => {
  const { type, ...props } = data;
  const Component = TYPE_TO_COMPONENT[type];

  if (Component) {
    return <Component {...props} />;
  }

  return <></>;
};

export default Widget;

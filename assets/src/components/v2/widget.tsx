import React from "react";

const TYPE_TO_COMPONENT = {};

const Widget = ({ data }) => {
  const { type, ...props } = data;
  const Component = TYPE_TO_COMPONENT[type];

  if (Component) {
    return <Component {...props} />;
  }

  return <></>;
};

export default Widget;

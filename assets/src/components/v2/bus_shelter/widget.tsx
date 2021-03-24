import React from "react";

const TYPE_TO_COMPONENT: Record<string, React.ComponentType<any>> = {};

type WidgetData = { type: string } & Record<string, any>;

interface Props {
  data: WidgetData;
}

const Widget: React.ComponentType<Props> = ({ data }) => {
  const { type, ...props } = data;
  const Component = TYPE_TO_COMPONENT[type];

  if (Component) {
    return <Component {...props} />;
  }

  return null;
};

export default Widget;
export { WidgetData };

import React, { useContext } from "react";

type WidgetData = { type: string } & Record<string, any>;

interface Props {
  data: WidgetData;
}

const MappingContext = React.createContext({});

const Widget: React.ComponentType<Props> = ({ data }) => {
  if (data === null) {
    return null;
  }

  const { type, ...props } = data;
  const typeToComponent = useContext(MappingContext);
  const Component = typeToComponent[type];

  if (Component) {
    return <Component {...props} />;
  }

  return <>{type}</>;
};

export default Widget;
export { WidgetData, MappingContext };

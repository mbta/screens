import { type ComponentType, createContext, useContext } from "react";

type WidgetData = { type: string } & Record<string, any>;

interface Props {
  data: WidgetData;
}

const MappingContext = createContext({});

const Widget: ComponentType<Props> = ({ data }) => {
  const typeToComponent = useContext(MappingContext);

  if (!data) return null;

  const { type, ...props } = data;
  const Component = typeToComponent[type];

  if (Component) return <Component {...props} />;

  return <>{type}</>;
};

export default Widget;
export { WidgetData, MappingContext };

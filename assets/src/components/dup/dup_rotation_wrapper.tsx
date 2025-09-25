import _ from "lodash";
import type { ElementType } from "react";

export const splitRotationFromPropNames = (
  WrappedComponent: ElementType,
  rotation: string,
) => {
  return (props: any) => {
    const rotationSuffixPattern = new RegExp(`_${rotation}$`);
    const modifiedProps = _.mapKeys(props, (_value, key) =>
      key.replace(rotationSuffixPattern, ""),
    );

    return <WrappedComponent {...modifiedProps} rotation={rotation} />;
  };
};

import _ from "lodash";
import React from "react";

export const splitRotationFromPropNames = (WrappedComponent: React.ElementType, rotation: string) => {
  return (props: any) => {
      
    const modifiedProps = _.mapKeys(props, (_value, key) => key.replace(`_${rotation}`, ""))

    return <WrappedComponent {...modifiedProps} rotation={rotation} />;
}
};
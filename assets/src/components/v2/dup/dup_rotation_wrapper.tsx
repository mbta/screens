import React, { ReactNode } from "react";

export const splitRotationFromPropNames = (WrappedComponent: React.ElementType, rotation: string) => {
  return class extends React.Component {
    render() {

      const modifiedProps = Object.keys(this.props).reduce((newProps: any, currentKey: string) => {
        const newKey = currentKey.replace("_one", "").replace("_two", "").replace("_zero", "")
        newProps[newKey] = this.props[currentKey as keyof Readonly<{}> & Readonly<{ children?: ReactNode; }>]
        return newProps
      }, {})

      return <WrappedComponent {...modifiedProps} rotation={rotation} />;
    }
  }
};
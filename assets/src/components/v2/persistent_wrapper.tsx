import React, { ComponentType, useState } from "react";

interface WrappedComponentProps {
  updateVisibleData: () => void;
}

interface Props {
  WrappedComponent: ComponentType<WrappedComponentProps>;
}

const PersistentWrapper: ComponentType<Props> = ({
  WrappedComponent,
  ...data
}) => {
  const [visibleData, setVisibleData] = useState(data);

  return (
    <WrappedComponent
      {...visibleData}
      updateVisibleData={() => setVisibleData(data)}
    />
  );
};

/**
 * Call this function on a `WrappedComponent` to allow it to persist across
 * data refreshes.
 *
 * Consider extending the `WrappedComponentProps` type exported by this module when
 * defining your `WrappedComponent`'s prop types.
 *
 * `WrappedComponent` must expect the following props:
 * - `updateVisibleData`: A callback that `WrappedComponent` can call to refresh the data displayed by the child component
 *   with the most recently received data.
 *
 * Any other props (e.g. data to be rendered) are passed through to `WrappedComponent` unchanged.
 */
const makePersistent =
  (Component: ComponentType<WrappedComponentProps>) =>
  ({ ...data }) => <PersistentWrapper {...data} WrappedComponent={Component} />;

export default makePersistent;
export { WrappedComponentProps };

import React, { ComponentType, useContext, useState } from "react";
import { LastFetchContext } from "Components/v2/screen_container";

interface WrappedComponentProps {
  updateVisibleData: () => void;
  lastUpdate: number | null;
}

interface Props {
  WrappedComponent: ComponentType<WrappedComponentProps>;
}

const PersistentWrapper: ComponentType<Props> = ({
  WrappedComponent,
  ...data
}) => {
  const lastFetch = useContext(LastFetchContext);

  const [visibleData, setVisibleData] = useState(data);

  return (
    <WrappedComponent
      {...visibleData}
      updateVisibleData={() => setVisibleData(data)}
      lastUpdate={lastFetch}
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
 * - `lastUpdate`: a **nullable** timestamp of the last successful data refresh, which `WrappedComponent` should use to
 *   sync its re-renders with the rest of the page. Used by components that use data refreshes to handle pagination.
 *
 * Any other props (e.g. data to be rendered) are passed through to `WrappedComponent` unchanged.
 */
const makePersistent =
  (Component: ComponentType<WrappedComponentProps>) =>
  ({ ...data }) => <PersistentWrapper {...data} WrappedComponent={Component} />;

export default makePersistent;
export { WrappedComponentProps };

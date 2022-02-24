import React, { ComponentType, useContext, useEffect, useState } from "react";
import { LastFetchContext } from "Components/v2/screen_container";

interface WrappedComponentProps {
  onFinish: () => void;
  lastUpdate: number | null;
}

interface Props {
  WrappedComponent: ComponentType<WrappedComponentProps>;
}

const PersistentWrapper: ComponentType<Props> = ({ WrappedComponent, ...data }) => {
  const lastFetch = useContext(LastFetchContext);

  const [visibleData, setVisibleData] = useState(data);
  const [isFinished, setIsFinished] = useState(false);
  const [renderKey, setRenderKey] = useState(0);

  const handleFinished = () => {
    setIsFinished(true);
  };

  useEffect(() => {
    if (isFinished) {
      setVisibleData(data);
      setRenderKey((n) => n + 1);
      setIsFinished(false);
    }
  }, [lastFetch]);

  return (
    <WrappedComponent
      {...visibleData}
      onFinish={handleFinished}
      key={renderKey}
      lastUpdate={lastFetch}
    />
  );
};

/**
 * Call this function on a `WrappedComponent` to allow it to persist across
 * data refreshes.
 *
 * Consider extending the `WrappedComponentProps` type exported by this module when
 * defining your `WrappedComponent`'s props.
 *
 * `WrappedComponent` must expect the following props:
 * - `onFinish`: A callback that `WrappedComponent` can call to indicate that it is ready to receive
 *   fresh data on the next refresh.
 * - `lastUpdate`: a **nullable** timestamp of the last successful data refresh, which `WrappedComponent` should use to
 *   sync its re-renders with the rest of the page.
 *
 * Any other props (e.g. data to be rendered) are passed through to `WrappedComponent` unchanged.
 */
const makePersistent =
  (Component: ComponentType<WrappedComponentProps>) =>
    ({ ...data }) =>
      <PersistentWrapper {...data} WrappedComponent={Component} />;

export default makePersistent;
export { WrappedComponentProps };

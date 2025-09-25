import { WrappedComponentProps } from "Components/persistent_wrapper";
import { LastFetchContext } from "Components/screen_container";
import { useContext, useEffect, useRef, useState } from "react";

interface UseRefreshPagingProps extends WrappedComponentProps {
  numPages: number;
}

/**
 * Enables pagination on data refreshes for components that are wrapped in Persistent Wrapper.
 */
const useRefreshPaging = ({
  numPages,
  updateVisibleData,
}: UseRefreshPagingProps) => {
  const lastUpdate = useContext(LastFetchContext);
  const prevUpdate = useRef(lastUpdate);
  const [pageIndex, setPageIndex] = useState(0);

  useEffect(() => {
    // Only do anything if this is a change to `lastUpdate`.
    if (lastUpdate !== null && lastUpdate !== prevUpdate.current) {
      // Don't advance the page if this is the first-ever update.
      if (prevUpdate !== null) {
        if (numPages > 1) {
          const newPageIndex = (pageIndex + 1) % numPages;
          if (newPageIndex === 0) {
            updateVisibleData();
          }
          setPageIndex(newPageIndex);
        } else {
          updateVisibleData();
        }
      }

      prevUpdate.current = lastUpdate;
    }
  }, [lastUpdate, numPages, pageIndex, updateVisibleData]);

  return pageIndex;
};

export default useRefreshPaging;

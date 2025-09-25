import { WrappedComponentProps } from "Components/persistent_wrapper";
import { LastFetchContext } from "Components/screen_container";
import { useContext, useEffect, useState } from "react";

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

  const [pageIndex, setPageIndex] = useState(0);
  const [isFirstRender, setIsFirstRender] = useState(true);

  useEffect(() => {
    if (lastUpdate != null) {
      if (isFirstRender) {
        setIsFirstRender(false);
      } else if (numPages > 1) {
        const newPageIndex = (pageIndex + 1) % numPages;
        if (newPageIndex === 0) {
          updateVisibleData();
        }
        setPageIndex(newPageIndex);
      } else {
        updateVisibleData();
      }
    }
  }, [lastUpdate]);

  return pageIndex;
};

export default useRefreshPaging;

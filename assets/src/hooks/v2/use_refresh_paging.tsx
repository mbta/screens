import { WrappedComponentProps } from "Components/v2/persistent_wrapper";
import { useEffect, useState } from "react";

interface UseRefreshPagingProps extends WrappedComponentProps {
  numPages: number;
}

/**
 * Enables pagination on data refreshes for components that are wrapped in Persistent Wrapper.
 */
const useRefreshPaging = ({
  numPages,
  lastUpdate,
  updateVisibleData,
}: UseRefreshPagingProps) => {
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

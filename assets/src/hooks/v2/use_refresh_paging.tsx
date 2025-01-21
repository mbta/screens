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
  onFinish,
  lastUpdate,
}: UseRefreshPagingProps) => {
  const [pageIndex, setPageIndex] = useState(0);
  const [isFirstRender, setIsFirstRender] = useState(true);

  useEffect(() => {
    if (lastUpdate != null) {
      if (isFirstRender) {
        setIsFirstRender(false);
      } else if (numPages > 1) {
        setPageIndex((i) => (i + 1) % numPages);
      } else {
        onFinish();
      }
    }
  }, [lastUpdate]);

  useEffect(() => {
    if (pageIndex === numPages - 1) {
      onFinish();
    }
  }, [pageIndex]);

  return pageIndex;
};

export default useRefreshPaging;

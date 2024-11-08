import { WrappedComponentProps } from "Components/v2/persistent_wrapper";
import { useEffect, useState } from "react";

interface Args extends WrappedComponentProps {
  numPages: number;
}

const useClientPaging = ({ numPages, onFinish, lastUpdate }: Args) => {
  const [pageIndex, setPageIndex] = useState(0);
  const [isFirstRender, setIsFirstRender] = useState(true);

  useEffect(() => {
    if (lastUpdate != null) {
      if (isFirstRender) {
        setIsFirstRender(false);
      } else {
        setPageIndex((i) => i + 1);
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

export default useClientPaging;

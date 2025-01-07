import { WrappedComponentProps } from "Components/v2/persistent_wrapper";
import { useEffect, useState } from "react";

interface Args extends WrappedComponentProps {
  numPages: number;
}

const useCustomPaging = ({ numPages, onFinish, lastUpdate }: Args) => {
  const [pageIndex, setPageIndex] = useState(0);

  useEffect(() => {
    const interval = setInterval(() => {
      setPageIndex((i) => i + 1);
    }, 2000); // 5 seconds
    return () => clearInterval(interval); // Cleanup on unmount
    }, [pageIndex]);

  useEffect(() => {
    if (pageIndex === numPages - 1) {
      onFinish();
    }
  }, [pageIndex]);

  return pageIndex;
};

export default useCustomPaging;

import { useState, useEffect, useRef, useCallback } from "react";

interface UseIntervalPagingProps {
  numPages: number; // Total number of pages to cycle through
  cycleIntervalMs: number; // In milliseconds, the interval for cycling pages (only used if advanceOnDataRefresh is false)
  onFinish: () => void; // Callback when cycling completes
}

/**
 * This hook acts as a way for components with multiple pages to advance
 * through their pages on a set time interval.
 */
function useIntervalPaging({
  numPages,
  cycleIntervalMs,
  onFinish,
}: UseIntervalPagingProps) {
  const [pageIndex, setPageIndex] = useState(0);
  const [isFinished, setIsFinished] = useState(false);

  // Use ref to keep stable references to timer interval without triggering re-renders
  const intervalRef = useRef<NodeJS.Timeout | null>(null);

  useEffect(() => {
    intervalRef.current = setInterval(() => {
      setPageIndex((prevPage) => {
        const nextPage = (prevPage + 1) % numPages;
        if (nextPage === 0) {
          setIsFinished(true);
        }

        return nextPage;
      });
    }, cycleIntervalMs);

    // Cleanup interval on unmount
    return () => {
      if (intervalRef.current) {
        clearInterval(intervalRef.current);
      }
    };
  }, [cycleIntervalMs, numPages]);

  // Handles calling the onFinish function in persistentWrapper
  useEffect(() => {
    if (pageIndex === 0 && isFinished === true) {
      onFinish();
      setIsFinished(false);
    }
  }, [isFinished]);
  return pageIndex;
}

export default useIntervalPaging;

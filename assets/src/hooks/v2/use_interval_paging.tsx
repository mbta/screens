import { useState, useEffect, useRef, useCallback } from "react";

interface UseIntervalPagingProps {
  numPages: number; // Total number of pages to cycle through
  cycleIntervalMs?: number; // In milliseconds, the interval for cycling pages (only used if advanceOnDataRefresh is false)
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
  // Use refs to keep stable references to numPages and interval without triggering re-renders
  const intervalRef = useRef<NodeJS.Timeout | null>(null);
  const numPagesRef = useRef(numPages);

  useEffect(() => {
    numPagesRef.current = numPages;
  }, [numPages]);

  // Callback that handles changing the state of pageIndex
  const advancePage = useCallback(() => {
    setPageIndex((prevIndex) => {
      return (prevIndex + 1) % numPagesRef.current;
    });
  }, []);

  // Start the interval for time-based advancement
  const startTimer = useCallback(() => {
    if (intervalRef.current) clearInterval(intervalRef.current); // Clear any existing timer
    if (cycleIntervalMs) {
      intervalRef.current = setInterval(() => {
        advancePage();
      }, cycleIntervalMs);
    }
  }, [cycleIntervalMs, advancePage]);

  // Cleanup the timer interval when the component unmounts or dependencies change
  useEffect(() => {
    if (cycleIntervalMs) {
      startTimer();
      return () => {
        if (intervalRef.current) clearInterval(intervalRef.current);
      };
    }
    // Hooks must return void or a cleanup function,
    // so we explicitly return undefined when no cleanup is necessary.
    return undefined;
  }, [cycleIntervalMs, startTimer]);

  useEffect(() => {
    if (pageIndex === 0) onFinish();
  }, [pageIndex]);

  return pageIndex;
}

export default useIntervalPaging;

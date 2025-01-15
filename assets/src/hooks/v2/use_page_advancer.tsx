import { useState, useEffect, useRef, useCallback } from "react";

interface UsePageAdvancerProps {
  numPages: number; // Total number of pages to cycle through
  advanceOnDataRefresh: boolean; // Whether to advance when data is refreshed
  cycleIntervalMs?: number; // In milliseconds, the interval for cycling pages (only used if advanceOnDataRefresh is false)
  lastUpdate?: number | null;
  onFinish: () => void; // Callback when cycling completes
}

/**
 * This hook acts as a way for components with multiple pages to advance
 * through their pages in one of two ways:
 *   1. Interval-based advancement (advances page every __ ms)
 *   2. Refresh-based advancement (advances page with every data refresh)
 */
function usePageAdvancer({
  numPages,
  cycleIntervalMs,
  advanceOnDataRefresh = false,
  lastUpdate,
  onFinish,
}: UsePageAdvancerProps) {
  const [pageIndex, setPageIndex] = useState(0);
  const intervalRef = useRef<NodeJS.Timeout | null>(null);

  // Use refs to keep stable references to numPages and onFinish
  const numPagesRef = useRef(numPages);
  const onFinishRef = useRef(onFinish);

  useEffect(() => {
    numPagesRef.current = numPages;
  }, [numPages]);

  useEffect(() => {
    onFinishRef.current = onFinish;
  }, [onFinish]);

  // Callback that handles changing the state of pageIndex
  const advancePage = useCallback(() => {
    setPageIndex((prevIndex) => {
      const nextIndex = (prevIndex + 1) % numPagesRef.current;
      if (nextIndex === 0) onFinishRef.current(); // Call onFinish when cycling completes
      return nextIndex;
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
    if (!advanceOnDataRefresh && cycleIntervalMs) {
      startTimer();
      return () => {
        if (intervalRef.current) clearInterval(intervalRef.current);
      };
    }
  }, [advanceOnDataRefresh, cycleIntervalMs, startTimer]);

  // Handle refresh-based advancement
  useEffect(() => {
    if (advanceOnDataRefresh && lastUpdate !== null) {
      advancePage();
    }
  }, [lastUpdate]);

  return pageIndex;
}

export default usePageAdvancer;

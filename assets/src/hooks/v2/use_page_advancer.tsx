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
    // Use refs to keep stable references to numPages and interval without triggering re-renders
  const intervalRef = useRef<NodeJS.Timeout | null>(null);
  const numPagesRef = useRef(numPages);

  useEffect(() => {
    numPagesRef.current = numPages;
  }, [numPages]);

  // Callback that handles changing the state of pageIndex
  const advancePage = useCallback(, []);

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
    // Hooks must return void or a cleanup function,
    // so we explicitly return undefined when no cleanup is necessary.
    return undefined;
  }, [advanceOnDataRefresh, cycleIntervalMs, startTimer]);

  // Handle refresh-based advancement
  useEffect(() => {
    if (advanceOnDataRefresh && lastUpdate !== null) {
      advancePage();
    }
  }, [lastUpdate]);

  useEffect(() => {
      // Call onFinish when cycling completes
    if (pageIndex === 0) onFinish();
  }, [pageIndex]);

  return pageIndex;
}

export default usePageAdvancer;

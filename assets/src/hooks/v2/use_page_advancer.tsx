import { useState, useEffect, useCallback } from "react";

interface UsePageAdvancerProps {
  numPages: number; // Total number of pages to cycle through
  advanceOnDataRefresh: boolean; // Whether to advance when data is refreshed
  cycleInterval?: number; // Time interval for cycling pages (only used if advanceOnDataRefresh is false)
  lastUpdate?: number | null;
  onFinish: () => void; // Callback
}

function usePageAdvancer({
  numPages,
  cycleInterval,
  advanceOnDataRefresh = false,
  lastUpdate,
  onFinish,
}: UsePageAdvancerProps) {
  const [pageIndex, setPageIndex] = useState(0);
  const [isFirstRender, setIsFirstRender] = useState(true);

  // Function for page advancement
  const advancePage = useCallback(() => {
    if (lastUpdate !== null) {
      if (isFirstRender) {
        setIsFirstRender(false);
      } else if (numPages > 1) {
        setPageIndex((i) => (i + 1) % numPages);
      } else {
        onFinish();
      }
    }
  }, [numPages, lastUpdate]);

  // Function for time-interval-based advancement
  const advanceByTime = useCallback(() => {
    const intervalId = setInterval(advancePage, cycleInterval);

    return () => clearInterval(intervalId); // Cleanup
  }, [advancePage, cycleInterval]);

  // Function for data-refresh-based advancement
  const advanceOnRefresh = useCallback(() => {
    advancePage();
  }, [lastUpdate]);

  // Choose the appropriate function to return
  const advance = advanceOnDataRefresh ? advanceOnRefresh : advanceByTime;

  // Start the appropriate page advancement type
  useEffect(() => {
    if (!advanceOnDataRefresh && cycleInterval) {
      return advanceByTime();
    } else {
      return advanceOnRefresh();
    }
  }, [lastUpdate, cycleInterval]);

  // TODO: I should maybe remove the advance function since it isn't needed anymore after refactoring
  return { pageIndex, advance };
}

export default usePageAdvancer;

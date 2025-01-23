import { useState, useEffect, useRef } from "react";

interface UseIntervalPagingProps {
  numPages: number; // Total number of pages to cycle through
  cycleIntervalMs: number; // In milliseconds, the interval for cycling pages
  updateVisibleData: () => void; // Callback when cycling completes
}

/**
 * This hook acts as a way for components with multiple pages to advance
 * through their pages on a set time interval.
 */
function useIntervalPaging({
  numPages,
  cycleIntervalMs,
  updateVisibleData,
}: UseIntervalPagingProps) {
  const [pageIndex, setPageIndex] = useState(0);
  const [isCycleFinished, setIsCycleFinished] = useState(false);

  // Use ref to keep stable references to timer interval without triggering re-renders
  const intervalRef = useRef<NodeJS.Timeout>();

  useEffect(() => {
    intervalRef.current = setInterval(() => {
      setPageIndex((prevPage) => {
        const nextPage = (prevPage + 1) % numPages;

        if (nextPage === 0) {
          // Updates the state of the data being displayed in case of any refreshes before cycling the page to index 0.
          setIsCycleFinished(true);
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

  // Handles calling the updateVisibleData function in persistentWrapper.
  // This needs to be done in a separate hook outside of the setInterval callback,
  // b/c you cannot change state in a different component within a callback function. 
  // So we trigger this hook within the callback function of setInterval with a boolean flag.
  useEffect(() => {
    if (isCycleFinished === true) {
      updateVisibleData();
      setIsCycleFinished(false);
    }
  }, [isCycleFinished]);
  return pageIndex;
}

export default useIntervalPaging;

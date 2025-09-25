import { useState, useEffect, useRef } from "react";

interface UseIntervalPagingProps {
  numPages: number; // Total number of pages to cycle through
  intervalMs: number; // In milliseconds, the interval that each page is visible before advancing
  updateVisibleData: () => void; // Callback when cycling completes
}

/**
 * This hook acts as a way for components with multiple pages to advance
 * through their pages on a set time interval.
 */
function useIntervalPaging({
  numPages,
  intervalMs,
  updateVisibleData,
}: UseIntervalPagingProps) {
  const [pageIndex, setPageIndex] = useState(0);
  const [isCycleFinished, setIsCycleFinished] = useState(false);

  // Use ref to keep stable references to timer interval without triggering re-renders
  const intervalRef = useRef<number>();

  useEffect(() => {
    intervalRef.current = window.setInterval(() => {
      setPageIndex((prevPage) => {
        const nextPage = (prevPage + 1) % numPages;

        if (nextPage === 0) {
          // Updates the state of the data being displayed in case of any refreshes before cycling the page to index 0.
          setIsCycleFinished(true);
        }

        return nextPage;
      });
    }, intervalMs);

    // Cleanup interval on unmount
    return () => {
      if (intervalRef.current) {
        window.clearInterval(intervalRef.current);
      }
    };
  }, [intervalMs, numPages]);

  // Handles calling the updateVisibleData function in persistentWrapper.
  // This needs to be done in a separate hook outside of the setInterval callback,
  // b/c you cannot change state in a different component within a callback function.
  // So we trigger this hook within the callback function of setInterval with a boolean flag.
  useEffect(() => {
    if (isCycleFinished === true) {
      updateVisibleData();
      setIsCycleFinished(false);
    }
  }, [isCycleFinished, updateVisibleData]);
  return pageIndex;
}

export default useIntervalPaging;

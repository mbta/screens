import { useEffect, useState } from "react";

/**
 * Creates a one-second timer, returning the current `Date`.
 */
export const useCurrentTime = (): { currentDateTime: Date } => {
  const [currentDateTime, setCurrentDateTime] = useState(new Date());
  useEffect(() => {
    const intervalTimer = setInterval(() => {
      setCurrentDateTime(new Date());
    }, 1000);

    return () => clearInterval(intervalTimer);
  }, []);

  return { currentDateTime };
};

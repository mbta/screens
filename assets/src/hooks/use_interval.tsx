import { useEffect, useRef } from "react";

// https://overreacted.io/making-setinterval-declarative-with-react-hooks/

const noop = () => {};

const useInterval = (callback: () => void, delay: number, skipInterval?: boolean) => {
  const savedCallback = useRef<() => void>(noop);

  // Remember the latest callback.
  useEffect(() => {
    if (!skipInterval && delay) {
      savedCallback.current = callback;
    }
  }, [callback, delay, skipInterval]);

  // Set up the interval.
  useEffect(() => {
    if (!skipInterval && delay) {
      const tick = () => {
        savedCallback.current();
      };
      const id = setInterval(tick, delay);
      return () => clearInterval(id);
    }
    return noop;
  }, [delay, skipInterval]);
};

export default useInterval;

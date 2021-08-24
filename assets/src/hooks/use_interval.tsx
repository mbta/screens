import { useEffect, useRef } from "react";

// https://overreacted.io/making-setinterval-declarative-with-react-hooks/

const noop = () => {};

const useInterval = (callback: () => void, delay: number) => {
  const savedCallback = useRef<() => void>(noop);

  // Remember the latest callback.
  useEffect(() => {
    savedCallback.current = callback;
  }, [callback]);

  // Set up the interval.
  useEffect(() => {
    const tick = () => {
      savedCallback.current();
    };
    const id = setInterval(tick, delay);
    return () => clearInterval(id);
  }, [delay]);
};

export default useInterval;

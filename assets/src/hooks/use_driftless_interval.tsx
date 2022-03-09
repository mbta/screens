import { useEffect, useRef, useState } from "react";

const noop = () => { };

const calculateMsToNextCall = (periodMs: number, offsetMs: number) => {
  // Milliseconds since Unix epoch
  const now = Date.now();
  // Count the number of periods elapsed since epoch, add one period, and convert back to milliseconds
  const nextPeriodStart = (Math.floor(now / periodMs) + 1) * periodMs;

  // p1 - - - - - - - - - - p2 - - - - - - - - - - p3 - - ...
  //     ^prev call  ^NOW   ^nextPeriodStart
  // |---|           |------|---|
  // offset          time to next call
  return nextPeriodStart - now + offsetMs;
};

const useDriftlessInterval = (callback: () => void, periodMs: number, offsetMs: number = 0) => {
  const savedCallback = useRef<() => void>(noop);
  const [tickSignal, setTickSignal] = useState<boolean>(false);

  useEffect(() => {
    savedCallback.current = callback;
  }, [callback]);

  useEffect(() => {
    const tick = () => {
      savedCallback.current();
      setTickSignal((value) => !value);
    };

    const id = setTimeout(tick, calculateMsToNextCall(periodMs, offsetMs));

    return () => clearTimeout(id);
  }, [tickSignal, periodMs, offsetMs]);
};

export default useDriftlessInterval;

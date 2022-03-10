import { useEffect, useRef, useState } from "react";

const noop = () => { };

const calculateMsToNextCall = (periodMs: number, offsetMs: number) => {
  // Now, as a Unix timestamp (Milliseconds since Unix epoch)
  const now = Date.now();

  // Timestamp of the start of the period we're currently in
  const currentPeriodStart = Math.floor(now / periodMs) * periodMs;
  // Timestamp of the call that happened (or will happen) this period
  const timestampOfCallThisPeriod = currentPeriodStart + offsetMs;

  let nextCallTimestamp;
  if (now < timestampOfCallThisPeriod) {
    // p1 - - - - - - - - - - p2 - - - - - - - - - - p3 - - ...
    // NOW^  ^next call
    // |-----|
    //    ^offset
    // The call during this period is still coming up
    nextCallTimestamp = timestampOfCallThisPeriod;
  } else {
    // p1 - - - - - - - - - - p2 - - - - - - - - - - p3 - - ...
    //       ^prev call  ^NOW       ^next call
    // |-----|                |-----|
    //    ^offset
    // The call during this period has already happened, so the next call happens during the next period
    nextCallTimestamp = timestampOfCallThisPeriod + periodMs;
  }

  return nextCallTimestamp - now;
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

    if (periodMs > 0) {
      const id = setTimeout(tick, calculateMsToNextCall(periodMs, offsetMs));
      return () => clearTimeout(id);
    }
    return;
  }, [tickSignal, periodMs, offsetMs]);
};

export default useDriftlessInterval;

import { useEffect, useRef, useState } from "react";

const noop = () => {};

/**
 * Given a repeating time interval pinned to the Unix epoch, plus an offset,
 * returns the time until the next tick.
 *
 * @param periodMs Milliseconds between each tick.
 * @param offsetMs Milliseconds to offset the timeline.
 * @returns Number of milliseconds until next tick.
 */
const driftlessInterval = (periodMs: number, offsetMs: number) => {
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

/**
 * Calls the provided function at intervals calculated by `driftlessInterval`.
 * When `periodMs` is `0`, the function is not called.
 */
const useDriftlessInterval = (
  callback: () => void,
  periodMs: number,
  offsetMs: number = 0,
) => {
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
      const id = setTimeout(tick, driftlessInterval(periodMs, offsetMs));
      return () => clearTimeout(id);
    }
    return;
  }, [tickSignal, periodMs, offsetMs]);
};

export { driftlessInterval };
export default useDriftlessInterval;

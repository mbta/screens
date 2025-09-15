import { type RefCallback, useLayoutEffect, useState, useRef } from "react";

import { hasOverflow } from "Util/utils";

// Types which use value equality
type Value = undefined | null | boolean | number | string | bigint;

/**
 * Detects when an element has overflow and allows re-rendering it using
 * different approaches ("steps"), trying each in order until the element does
 * not overflow or the steps run out.
 *
 *
 * ## Example
 *
 * Render `fullText` if it does not overflow its container, else `abbrevText`:
 *
 * ```
 * const { ref, step: text } = useAutoSize([fullText, abbrevText]);
 * return <div ref={ref}>{text}</div>
 * ```
 *
 *
 * ## Example
 *
 * Render `text` at the largest font size that does not overflow its container:
 *
 * ```
 * const { ref, step } = useAutoSize(["large", "medium", "small"], text);
 * return <div ref={ref} style={{ fontSize: step }}>{text}</div>;
 * ```
 *
 * Note `text` is used as a "key" since its content could affect whether the
 * container overflows. When the key changes (or the steps themselves change),
 * the overflow-checking process restarts from the first step.
 *
 *
 * ## Notes
 *
 * - The returned `ref` must be attached to the element to be checked for
 *   overflow. Logically this should have a constrained width or height, and
 *   have content whose size depends on the returned `step`.
 *
 * - Similar to `deps` for built-in hooks, there is generally a "correct" value
 *   for `key` and it is formed by combining any values *not* in `steps` that
 *   could affect the size of the target element's content. Omitting a relevant
 *   value can result in content having the wrong (possibly overflowing) size.
 */
const useAutoSize = <T extends Value>(
  steps: readonly T[],
  key?: Value,
): { ref: RefCallback<Element>; step: T } => {
  const initialSteps = useRef(steps);
  const [element, setElement] = useState<Element | null>(null);
  const [remainingSteps, setRemainingSteps] = useState(steps);

  // Reset overflow checking when the key changes. Unconditionally changes the
  // object identity of `remainingSteps` so the main hook will check again for
  // overflow even if the steps are unchanged.
  useLayoutEffect(() => setRemainingSteps([...initialSteps.current]), [key]);

  // Observe changes to `steps` but only reset the process when it "really"
  // changes, using a ref to keep the previous value around for comparison.
  // Required to prevent infinite render loops, due to array literals in the
  // body of a component technically being a new object on every render.
  useLayoutEffect(() => {
    if (initialSteps.current.some((step, index) => steps[index] !== step)) {
      initialSteps.current = steps;
      setRemainingSteps(steps);
    }
  }, [steps]);

  // The main "loop". When the element mounts or `remainingSteps` changes, if
  // the element has overflow and we have steps remaining, advance to the next
  // step. This is a change to `remainingSteps` and so itself causes the effect
  // to run again, but on the next render, with the new step value.
  useLayoutEffect(() => {
    if (remainingSteps.length > 1 && element && hasOverflow(element)) {
      setRemainingSteps(remainingSteps.slice(1));
    }
  }, [element, remainingSteps]);

  return { ref: setElement, step: remainingSteps[0] };
};

export default useAutoSize;

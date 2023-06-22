import { useEffect, useRef, useState } from "react";

interface UseTextResizerArgs<T> {
  sizes: T[];
  maxHeight: number;
  resetDependencies: any[];
}

interface UseTextResizerReturn<T> {
  ref: React.RefObject<HTMLDivElement>;
  size: T;
  isDone: boolean;
}

/**
 * This hook creates a ref to be placed on an element with text and uses the `useEffect` hook
 * to find the largest size that still allows the text to fit in the element. If none of the sizes
 * fit, the smallest size is selected.
 *
 * This hook can be used with a list of CSS classes or modifiers for text resizing
 * in a single containing element with a single CSS class.
 *
 * ```
 * const {ref, size} = useTextResizer({
 *   sizes: ["small", "medium", "large"],
 *   maxHeight: 100,
 *   resetDependencies: [textContent]
 * });
 *
 * return <div className={classWithModifier("text-el", size)} ref={ref}>{textContent}</div>;
 * ```
 *
 * The hook can also be given a list of arbitrary values (e.g. from an enum), which the calling
 * component can use however it likes to adjust content and styles until the ref'd element
 * has the desired maxHeight.
 *
 * ```
 * enum SizingStep {
 *   AbbreviateAndShrink,
 *   Abbreviate,
 *   FullSize
 * }
 *
 * const {ref, size: selectedStep} = useTextResizer({
 *   sizes: [SizingStep.AbbreviateAndShrink, SizingStep.Abbreviate, SizingStep.FullSize],
 *   maxHeight: 100,
 *   resetDependencies: [anything, that, affects, content, being, shown]
 * });
 *
 * let abbreviate = false;
 * let shrink = false;
 * switch (selectedStep) {
 *   case SizingStep.FullSize:
 *     break;
 *   case SizingStep.Abbreviate:
 *     abbreviate = true;
 *     break;
 *   case SizingStep.AbbreviateAndShrink:
 *     abbreviate = true;
 *     shrink = true;
 *     break;
 * }
 *
 * return <div className={shrink ? "text-el--small" : "text-el"}>{abbreviate ? content.abbrev : content.full}</div>;
 * ```
 *
 * @param sizes A list of values (CSS modifiers, enum members, or anything else) that represent the sizes for the given element.
 *              Elements should be ordered smallest to largest.
 * @param maxHeight The maximum height of the container in which the text will be placed.
 * @param resetDependencies A list of dependencies that should be used to reset the sizeIndex.
 * @returns - A ref,
 *          - the selected size value,
 *          - and a boolean indicating whether the hook is done resizing--either because the text fits, or because the smallest size has been reached.
 */
const useTextResizer = <T,>({
  sizes,
  maxHeight,
  resetDependencies,
}: UseTextResizerArgs<T>): UseTextResizerReturn<T> => {
  const [sizeIndex, setSizeIndex] = useState(sizes.length - 1);
  const [isDone, setIsDone] = useState(false);
  const ref = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (ref.current !== null) {
      const height = ref.current.clientHeight;
      if (height > maxHeight && sizeIndex > 0) {
        setSizeIndex(sizeIndex - 1);
        setIsDone(false);
      }
      if (height <= maxHeight || sizeIndex === 0) {
        setIsDone(true);
      }
    }
  });

  // This state-resetting effect must run *after* the height-measuring
  // effect. Otherwise, we run into this problem case:
  // 1. Current state: Resized properly, isDone is true
  // 2. Data changes to something with long text that needs shrinking
  // 3. State-resetting hook runs, sets isDone to false
  // 4. Height-measuring hook runs *in the same render*, before the
  //    content drawn on the page has changed to reflect the new data.
  //    Sets isDone back to true because the previous content still fits.
  // 5. Page re-renders with isDone still true. The component using this hook
  //    sets some conditional styles that hide overflow, this hook measures
  //    the ref'd element as fitting, and stops trying smaller sizes.
  //    --> The new content doesn't get resized properly.
  useEffect(() => {
    setSizeIndex(sizes.length - 1);
    setIsDone(false);
  }, resetDependencies);

  const size = sizes[sizeIndex];

  return { ref, size, isDone };
};

export default useTextResizer;

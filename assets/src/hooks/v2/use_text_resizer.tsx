import { useEffect, useRef, useState } from "react";

interface UseTextResizerArgs<T> {
  sizes: T[];
  maxHeight: number;
  resetDependencies: any[];
}

interface UseTextResizerReturn<T> {
  ref: React.RefObject<HTMLDivElement>;
  size: T;
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
 * @returns A ref and the selected size value.
 */
const useTextResizer = <T,>({
  sizes,
  maxHeight,
  resetDependencies,
}: UseTextResizerArgs<T>): UseTextResizerReturn<T> => {
  const [sizeIndex, setSizeIndex] = useState(sizes.length - 1);
  const ref = useRef<HTMLDivElement>(null);

  useEffect(() => {
    setSizeIndex(sizes.length - 1);
  }, resetDependencies);

  useEffect(() => {
    if (ref.current !== null) {
      const height = ref.current.clientHeight;
      if (height > maxHeight && sizeIndex > 0) {
        setSizeIndex(sizeIndex - 1);
      }
    }
  });

  const size = sizes[sizeIndex];

  return { ref, size };
};

export default useTextResizer;

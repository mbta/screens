import { useEffect, useLayoutEffect, useRef, useState } from "react";

interface UseTextResizerArgs {
  sizes: string[];
  maxHeight: number;
  resetDependencies: any[];
}

interface UseTextResizerReturn {
  ref: React.MutableRefObject<null>;
  size: string;
}

/**
 * This hook creates a ref to be placed on an element with text and uses the `useLayoutEffect` hook
 * to find the largest font size that still allows the text to fit in the element. If none of the sizes
 * fit, the smallest size is selected. This hook should be used for text resizing in a single containing
 * element with a single CSS class. It does not work well with containers that require more complicated
 * resizing, e.g. Subway Status rows.
 * @param sizes A list of CSS modifiers that represent the font size for the given element. Elements should be ordered smallest to largest.
 * @param maxHeight The maximum height of the container in which the text will be placed.
 * @param resetDependencies A list of dependencies that should be used to reset the sizeIndex.
 * @returns A ref and the selected CSS modifier.
 */
const useTextResizer = ({
  sizes,
  maxHeight,
  resetDependencies,
}: UseTextResizerArgs): UseTextResizerReturn => {
  const [sizeIndex, setSizeIndex] = useState(sizes.length - 1);
  const ref = useRef(null);

  useEffect(() => {
    setSizeIndex(sizes.length - 1);
  }, resetDependencies);

  useLayoutEffect(() => {
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

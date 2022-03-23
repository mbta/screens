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
    const height = ref.current.clientHeight;
    if (height > maxHeight && sizeIndex > 0) {
      setSizeIndex(sizeIndex - 1);
    }
  });

  const size = sizes[sizeIndex];

  return { ref, size };
};

export default useTextResizer;

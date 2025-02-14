import { useLocation } from "react-router-dom";

/**
 * Pulls out any valid query param key/values from the URL into a Map.
 * Returns an empty Map if there are no valid query param keys in the URL.
 */
export const useQueryParams = (
  validParamKeys: string[] = [],
): Map<string, string> => {
  const { search } = useLocation();
  const urlParams = new URLSearchParams(search);

  const paramMap = new Map<string, string>();
  validParamKeys.forEach((key) => {
    const value = urlParams.get(key);
    if (value) {
      paramMap.set(key, value);
    }
  });

  return paramMap;
};

import { useLocation } from "react-router-dom";

// On Bus Screens update the state of their data based on values passed in through query params
// This list allows us to filter and only pass through valid params
export const URL_PARAMS_BY_SCREEN_TYPE = {
  on_bus_v2: ["route_id", "stop_id", "trip_id"],
};

/**
 * Pulls out any valid query param key/values from the URL into a Map.
 * Returns an empty Map if there are no valid query param keys in the URL.
 */
export const getQueryParamMap = (
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

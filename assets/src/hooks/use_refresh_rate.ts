import _ from "lodash";
import { useMemo } from "react";
import { fetchDatasetValue, getDatasetValue } from "Util/dataset";
import { useScreenID } from "./use_screen_id";

interface RefreshRateConfig {
  refreshRateMs: number;
  refreshRateOffsetMs: number;
}

const useRefreshRate = (): RefreshRateConfig => {
  const screenId = useScreenID();

  return useMemo(() => {
    const refreshRate = fetchDatasetValue("refreshRate");
    const refreshRateOffset = getDatasetValue("refreshRateOffset") || "0";
    const screenIdsWithOffsetMap = getDatasetValue("screenIdsWithOffsetMap");

    const refreshRateMs = parseFloat(refreshRate) * 1000;
    let refreshRateOffsetMs;

    if (screenIdsWithOffsetMap) {
      const screens = JSON.parse(screenIdsWithOffsetMap);
      refreshRateOffsetMs =
        _.find(screens, { id: screenId }).refresh_rate_offset * 1000;
    } else {
      refreshRateOffsetMs = parseFloat(refreshRateOffset) * 1000;
    }

    return { refreshRateMs, refreshRateOffsetMs };
  }, [screenId]);
};

export default useRefreshRate;

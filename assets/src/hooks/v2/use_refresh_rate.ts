import _ from "lodash";
import { useMemo } from "react";
import { fetchDatasetValue, getDatasetValue } from "Util/dataset";
import { isOFM } from "Util/outfront";
import { useScreenID } from "./use_screen_id";

interface RefreshRateConfig {
  refreshRateMs: number;
  refreshRateOffsetMs: number;
}

const useRefreshRate = (): RefreshRateConfig => {
  const screenId = useScreenID();
  // Live OFM screens ignore any configured refreshRate.
  // Hardcoding to 0 prevents an interval from being started unnecessarily.
  const refreshRate = isOFM() ? "0" : fetchDatasetValue("refreshRate");
  const refreshRateOffset = getDatasetValue("refreshRateOffset") || "0";
  const screenIdsWithOffsetMap = getDatasetValue("screenIdsWithOffsetMap");

  const refreshRateMs = parseFloat(refreshRate) * 1000;

  const refreshRateOffsetMs = useMemo(() => {
    if (screenIdsWithOffsetMap) {
      const screens = JSON.parse(screenIdsWithOffsetMap);
      return _.find(screens, { id: screenId }).refresh_rate_offset * 1000;
    }

    return parseFloat(refreshRateOffset) * 1000;
  }, []);

  return {
    refreshRateMs,
    refreshRateOffsetMs,
  };
};

export default useRefreshRate;

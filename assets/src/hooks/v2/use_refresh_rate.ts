import _ from "lodash";
import { useMemo, useState } from "react";
import { fetchDatasetValue, getDatasetValue } from "Util/dataset";
import { useReceiveMessage } from "Util/inspector";
import { isOFM } from "Util/outfront";
import { useScreenID } from "./use_screen_id";

interface RefreshRateConfig {
  refreshRateMs: number;
  refreshRateOffsetMs: number;
}

const useRefreshRate = (): RefreshRateConfig => {
  const screenId = useScreenID();
  const refreshRateOverride = useInspectorOverride();

  return useMemo(() => {
    // Live OFM screens ignore any configured refreshRate.
    // Hardcoding to 0 prevents an interval from being started unnecessarily.
    const refreshRate = isOFM() ? "0" : fetchDatasetValue("refreshRate");
    const refreshRateOffset = getDatasetValue("refreshRateOffset") || "0";
    const screenIdsWithOffsetMap = getDatasetValue("screenIdsWithOffsetMap");

    const refreshRateMs = refreshRateOverride ?? parseFloat(refreshRate) * 1000;

    let refreshRateOffsetMs;

    if (screenIdsWithOffsetMap) {
      const screens = JSON.parse(screenIdsWithOffsetMap);
      refreshRateOffsetMs =
        _.find(screens, { id: screenId }).refresh_rate_offset * 1000;
    } else {
      refreshRateOffsetMs = parseFloat(refreshRateOffset) * 1000;
    }

    return { refreshRateMs, refreshRateOffsetMs };
  }, [screenId, refreshRateOverride]);
};

const useInspectorOverride = (): number | null => {
  const [override, setOverride] = useState<number | null>(null);

  useReceiveMessage((message) => {
    if (message.type == "set_refresh_rate") setOverride(message.ms);
  });

  return override;
};

export default useRefreshRate;

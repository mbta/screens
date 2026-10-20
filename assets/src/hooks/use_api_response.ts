import { useEffect, useMemo, useState } from "react";
import { captureException } from "@sentry/react";
import useSWR from "swr";

import { WidgetData } from "Components/widget";
import { getDatasetValue } from "Util/dataset";
import { sendToInspector, useReceiveFromInspector } from "Util/inspector";
import { getRotationIndex, getVersion } from "Util/outfront";
import { getScreenSide, isRealScreen } from "Util/utils";

import { driftlessInterval } from "./use_driftless_interval";
import useRefreshRate from "./use_refresh_rate";

const BASE_PATH = "/v2/api/screen";

// The default SWR retry handler uses exponential backoff with random jitter,
// taking the configured `errorRetryInterval` as the minimum possible interval
// for the first retry, the math taking at most 8 retries into account. With
// this value at 250ms, the average interval is initially 500ms and doubles
// with each retry up to 64s at 8+ retries. (N.B. this is an undocumented
// implementation detail, and may change in future versions of the library)
const MIN_ERROR_RETRY_MS = 250;

// After this long without refreshing data, consider the previous data "stale"
// and don't continue to display it.
const STALE_THRESHOLD_MS = 60_000;

type SimulationData = { fullPage: WidgetData; flexZone: WidgetData[] };

const DISABLED_RESPONSE = { state: "disabled" } as const;
const FAILURE_RESPONSE = { state: "failure" } as const;
const LOADING_RESPONSE = { state: "loading" } as const;

type ApiResponse =
  | { state: "success"; data: WidgetData }
  | { state: "simulation_success"; data: SimulationData }
  | typeof DISABLED_RESPONSE
  | typeof FAILURE_RESPONSE
  | typeof LOADING_RESPONSE;

type RawResponse = {
  data: null | WidgetData | { full_page: WidgetData; flex_zone: WidgetData[] };
  disabled: boolean;
  force_reload: boolean;
};

const apiResponseFetcher = (path: string): Promise<ApiResponse> =>
  fetch(path)
    .then((response) => {
      if (response.ok) {
        return response.json();
      } else {
        throw new Error(`API response status error: ${response.status}`);
      }
    })
    .then(({ data, disabled, force_reload }: RawResponse) => {
      if (force_reload) {
        window.location.reload();
        return DISABLED_RESPONSE;
      } else if (disabled) {
        return DISABLED_RESPONSE;
      } else if (data === null) {
        return FAILURE_RESPONSE;
      } else if ("full_page" in data) {
        return {
          state: "simulation_success",
          data: { fullPage: data.full_page, flexZone: data.flex_zone },
        };
      } else {
        return { state: "success", data };
      }
    });

const buildApiPath = (screenId: string, appendPath?: string): string => {
  const base = getDatasetValue("apiOrigin") ?? document.baseURI;
  const path = [BASE_PATH, screenId, appendPath].filter(Boolean).join("/");

  const url = new URL(path, base);

  const params: Record<string, string | null | undefined> = {
    is_real_screen: isRealScreen() ? "true" : null,
    last_refresh: getDatasetValue("lastRefresh"),
    requestor: getDatasetValue("requestor"),
    rotation_index: getRotationIndex(),
    screen_side: getScreenSide(),
    version: getVersion(),
  };

  for (const [key, value] of Object.entries(params)) {
    if (value) url.searchParams.append(key, value);
  }

  return url.toString();
};

interface UseApiResponseReturn {
  apiResponse: ApiResponse;
  requestCount: number;
  lastSuccess: number | null;
}

const useBaseApiResponse = ({
  id,
  appendPath,
}: {
  id: string;
  appendPath?: string;
}): UseApiResponseReturn => {
  const { refreshRateMs, refreshRateOffsetMs } = useRefreshRate();

  const [requestCount, setRequestCount] = useState<number>(0);
  const [lastSuccess, setLastSuccess] = useState<number | null>(null);
  const [isStale, setIsStale] = useState(false);

  const apiPath = useMemo(() => buildApiPath(id, appendPath), [id, appendPath]);
  const isPaused = useInspectorPause();

  const { data, mutate } = useSWR(apiPath, apiResponseFetcher, {
    errorRetryInterval: MIN_ERROR_RETRY_MS,
    fallbackData: LOADING_RESPONSE,
    isPaused: () => isPaused,
    onError: (error) => {
      captureException(error);
      setRequestCount((count) => count + 1);
    },
    onSuccess: () => {
      setIsStale(false);
      setLastSuccess(Date.now());
      setRequestCount((count) => count + 1);
    },
    refreshInterval:
      refreshRateMs === 0
        ? 0 // disables interval
        : () => driftlessInterval(refreshRateMs, refreshRateOffsetMs),
    // On real screens, disable default features that look at the state of the
    // browser window or the "visibility" of content; these are not relevant to
    // our usage and may not be reliable there
    refreshWhenHidden: isRealScreen(),
    revalidateOnFocus: !isRealScreen(),
  });

  useInspectorControls(mutate, lastSuccess);

  useEffect(() => {
    const timer = setTimeout(() => setIsStale(true), STALE_THRESHOLD_MS);
    return () => clearTimeout(timer);
  }, [lastSuccess]);

  const apiResponse = isStale && !isPaused ? FAILURE_RESPONSE : data;
  return { apiResponse, requestCount, lastSuccess };
};

const useInspectorPause = (): boolean => {
  const [isPaused, setIsPaused] = useState(false);

  useReceiveFromInspector((message) => {
    if (message.type === "set_refresh_paused") setIsPaused(message.isPaused);
  });

  return isPaused;
};

const useInspectorControls = (
  refreshFn: () => void,
  lastSuccess: number | null,
): void => {
  useReceiveFromInspector((message) => {
    if (message.type === "refresh_data") refreshFn();
  });

  useEffect(() => {
    if (lastSuccess) {
      sendToInspector({ type: "data_refreshed", timestamp: lastSuccess });
    }
  }, [lastSuccess]);
};

const useApiResponse = ({ id }): UseApiResponseReturn =>
  useBaseApiResponse({ id });

const useSimulationApiResponse = ({ id }): UseApiResponseReturn =>
  useBaseApiResponse({ id, appendPath: "simulation" });

// When running the packaged client, use a distinct API route that allows
// cross-origin requests, since these clients are loaded from a local HTML file
// (and thus their data requests to our server are cross-origin). This route is
// otherwise identical to the one used by `useApiResponse`.
const useOutfrontApiResponse = ({ id }): UseApiResponseReturn =>
  useBaseApiResponse({ id, appendPath: "dup" });

export default useApiResponse;
export type { ApiResponse, SimulationData };
export { useOutfrontApiResponse, useSimulationApiResponse };

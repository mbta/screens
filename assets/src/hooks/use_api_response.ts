import { useEffect, useMemo, useState } from "react";
import { captureException } from "@sentry/react";
import useSWR from "swr";

import { WidgetData } from "Components/widget";
import { getDatasetValue } from "Util/dataset";
import { sendToInspector, useReceiveFromInspector } from "Util/inspector";
import { getRotationIndex, getVersion } from "Util/outfront";
import { getScreenSide, isRealScreen } from "Util/utils";
import { report } from "Util/sentry";

import { driftlessInterval } from "./use_driftless_interval";
import useRefreshRate from "./use_refresh_rate";

const BASE_PATH = "/v2/api/screen";
const STALE_THRESHOLD_MS = 60_000;

type SimulationResponse = { full_page: WidgetData; flex_zone: WidgetData[] };
type DataResponse<T extends SimulationResponse | WidgetData> = { data: T };
type SimulationData = { fullPage: WidgetData; flexZone: WidgetData[] };

type Success = { state: "success"; data: WidgetData };
type SimulationSuccess = { state: "simulation_success"; data: SimulationData };
const DISABLED_RESPONSE = { state: "disabled" } as const;
const FAILURE_RESPONSE = { state: "failure" } as const;
const LOADING_RESPONSE = { state: "loading" } as const;

type ApiResponse =
  | Success
  | SimulationSuccess
  | typeof DISABLED_RESPONSE
  | typeof FAILURE_RESPONSE
  | typeof LOADING_RESPONSE;

const apiResponseFetcher = (path: string): Promise<ApiResponse> =>
  fetch(path)
    .then((response) => response.json())
    .then((json) => {
      if (json.force_reload) {
        window.location.reload();
        return DISABLED_RESPONSE;
      } else if (json.disabled) {
        return DISABLED_RESPONSE;
      } else if (json.data) {
        if ("full_page" in json.data) {
          const { data } = json as DataResponse<SimulationResponse>;

          return {
            state: "simulation_success",
            data: { fullPage: data.full_page, flexZone: data.flex_zone },
          };
        } else {
          const { data } = json as DataResponse<WidgetData>;
          return { state: "success", data };
        }
      } else {
        return FAILURE_RESPONSE;
      }
    });

const isSuccess = (
  response: ApiResponse,
): response is Success | SimulationSuccess =>
  ["success", "simulation_success"].includes(response.state);

const useApiPath = (screenId: string, appendPath?: string): string => {
  return useMemo(() => {
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
  }, [screenId, appendPath]);
};

interface UseBaseApiResponseOpts {
  id: string;
  appendPath?: string;
}

interface UseApiResponseReturn {
  apiResponse: ApiResponse;
  requestCount: number;
  lastSuccess: number | null;
}

const useTimer = (ms: number) => {
  const [hasExpired, setHasExpired] = useState(false);
  const [resetTrigger, setResetTrigger] = useState(false);

  useEffect(() => {
    setHasExpired(false);
    const timer = setTimeout(() => setHasExpired(true), ms);
    return () => clearTimeout(timer);
  }, [resetTrigger]);

  return { hasExpired, reset: () => setResetTrigger((t) => !t) };
};

const useBaseApiResponse = ({
  id,
  appendPath,
}: UseBaseApiResponseOpts): UseApiResponseReturn => {
  const { refreshRateMs, refreshRateOffsetMs } = useRefreshRate();
  const [requestCount, setRequestCount] = useState<number>(0);
  const [lastSuccess, setLastSuccess] = useState<number | null>(null);
  const { hasExpired, reset: resetStaleTimer } = useTimer(STALE_THRESHOLD_MS);
  const isPaused = useInspectorPause();

  const apiPath = useApiPath(id, appendPath);

  const { data, mutate } = useSWR(apiPath, apiResponseFetcher, {
    fallbackData: LOADING_RESPONSE,
    isPaused: () => isPaused,
    onError: (error) => {
      setRequestCount((count) => count + 1);
      captureException(error);
    },
    onErrorRetry: (_error, _key, _config, revalidate, opts) => {
      setTimeout(
        () => revalidate(opts),
        // Retry less often with more failures, max 8 seconds at 8+ retries.
        Math.pow(Math.min(opts.retryCount / 2, 4), 1.5) * 1_000,
      );
    },
    onSuccess: (response) => {
      setRequestCount((count) => count + 1);
      if (isSuccess(response)) {
        resetStaleTimer();
        setLastSuccess(Date.now());
      }
    },
    refreshInterval: () =>
      driftlessInterval(refreshRateMs, refreshRateOffsetMs),
    // Disable default features that look at the state of the browser window or
    // the "visibility" of content; these are not relevant to our usage and may
    // not be reliable on screen devices
    refreshWhenHidden: true,
    revalidateOnFocus: false,
  });

  useInspectorControls(mutate, lastSuccess);

  const apiResponse = hasExpired ? FAILURE_RESPONSE : data;
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
    if (message.type === "set_refresh_paused") null;
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

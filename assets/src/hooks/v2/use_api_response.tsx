import { WidgetData } from "Components/v2/widget";
import useDriftlessInterval from "Hooks/use_driftless_interval";
import React, { useEffect, useMemo, useState } from "react";
import { getDatasetValue } from "Util/dataset";
import { sendToInspector, useReceiveFromInspector } from "Util/inspector";
import { isDup, isOFM, isTriptych, getTriptychPane } from "Util/outfront";
import { getScreenSide, isRealScreen } from "Util/util";
import * as SentryLogger from "Util/sentry";
import { ROTATION_INDEX } from "Components/v2/dup/rotation_index";
import { DUP_VERSION } from "Components/v2/dup/version";
import { TRIPTYCH_VERSION } from "Components/v2/triptych/version";
import useRefreshRate from "./use_refresh_rate";

const BASE_PATH = "/v2/api/screen";
const MINUTE_IN_MS = 60_000;
const OUTFRONT_BASE_URI = "https://screens.mbta.com";

type SimulationResponse = { full_page: WidgetData; flex_zone: WidgetData[] };

type RawResponse = {
  data: SimulationResponse | WidgetData | null;
  disabled: boolean;
  force_reload: boolean;
};

type SimulationData = { fullPage: WidgetData; flexZone: WidgetData[] };

type ApiResponse =
  // The request was successful.
  | { state: "success"; data: WidgetData }
  | { state: "simulation_success"; data: SimulationData }
  // The request was successful, but this screen is disabled via config.
  | { state: "disabled" }
  // Either:
  // - The request failed.
  // - The server responded, but did not successfully fetch data. Riders may
  //   still be able to find data from other sources.
  | { state: "failure" }
  | { state: "loading" };

const FAILURE_RESPONSE: ApiResponse = { state: "failure" };
const LOADING_RESPONSE: ApiResponse = { state: "loading" };

const rawResponseToApiResponse = (response: RawResponse): ApiResponse => {
  if (response.disabled) {
    return { state: "disabled" };
  } else if (response.data) {
    const data = response.data;

    if ("full_page" in data) {
      return {
        state: "simulation_success",
        data: { fullPage: data.full_page, flexZone: data.flex_zone },
      };
    } else {
      return { state: "success", data };
    }
  } else {
    return { state: "failure" };
  }
};

const doFailureBuffer = (
  lastSuccess: number | null,
  setApiResponse: React.Dispatch<React.SetStateAction<ApiResponse>>,
  apiResponse: ApiResponse = FAILURE_RESPONSE,
) => {
  if (lastSuccess == null) {
    // We haven't had a successful request since initial page load.
    // Show the "no data" state.
    setApiResponse(FAILURE_RESPONSE);
  } else {
    const elapsedMs = Date.now() - lastSuccess;

    if (elapsedMs < MINUTE_IN_MS) {
      setApiResponse((state) => state);
    }
    if (elapsedMs >= MINUTE_IN_MS) {
      // This will trigger until a success API response is received.
      setApiResponse((prevApiResponse) => {
        if (isSuccess(prevApiResponse)) {
          SentryLogger.info("Entering no-data state.");
        }
        return apiResponse;
      });
    }
  }
};

const isSuccess = (response: ApiResponse) =>
  response != null &&
  ["success", "simulation_success"].includes(response.state);

const loggingParams = () => {
  if (isDup()) {
    return {
      rotation_index: ROTATION_INDEX.toString(),
      version: DUP_VERSION,
    };
  } else if (isTriptych()) {
    return {
      pane: getTriptychPane() ?? "UNKNOWN",
      version: TRIPTYCH_VERSION,
    };
  } else {
    return {};
  }
};

const useApiPath = (screenId: string, appendPath?: string): string => {
  return useMemo(() => {
    const base = isOFM() ? OUTFRONT_BASE_URI : document.baseURI;
    const path = [
      BASE_PATH,
      getDatasetValue("isPending") === "true" ? "pending" : null,
      screenId,
      appendPath,
    ]
      .filter(Boolean)
      .join("/");

    const url = new URL(path, base);

    const params: Record<string, string | null | undefined> = {
      is_real_screen: isRealScreen() ? "true" : null,
      last_refresh: getDatasetValue("lastRefresh"),
      requestor:
        getDatasetValue("requestor") ?? (isRealScreen() ? "real_screen" : null),
      screen_side: getScreenSide(),
      ...loggingParams(),
    };

    for (const [key, value] of Object.entries(params)) {
      if (value) url.searchParams.append(key, value);
    }

    return url.toString();
  }, [screenId, appendPath]);
};

interface UseApiResponseReturn {
  apiResponse: ApiResponse;
  requestCount: number;
  lastSuccess: number | null;
}

const useBaseApiResponse = (
  id: string,
  appendPath?: string,
): UseApiResponseReturn => {
  const { refreshRateMs, refreshRateOffsetMs } = useRefreshRate();
  const [apiResponse, setApiResponse] = useState<ApiResponse>(LOADING_RESPONSE);
  const [requestCount, setRequestCount] = useState<number>(0);
  const [lastSuccess, setLastSuccess] = useState<number | null>(null);
  const apiPath = useApiPath(id, appendPath);

  const fetchData = async () => {
    try {
      const now = Date.now();
      const result = await fetch(apiPath);
      const rawResponse: RawResponse = await result.json();

      if (rawResponse.force_reload) {
        window.location.reload();
      }

      const apiResponse = rawResponseToApiResponse(rawResponse);

      if (apiResponse.state == "failure") {
        doFailureBuffer(lastSuccess, setApiResponse, apiResponse);
      } else {
        setApiResponse((prevApiResponse) => {
          if (!isSuccess(prevApiResponse)) {
            SentryLogger.info("Exiting no-data state.");
          }
          return apiResponse;
        });
        setLastSuccess(now);
      }
    } catch {
      doFailureBuffer(lastSuccess, setApiResponse);
    }

    setRequestCount((count) => count + 1);
  };

  // Fetch data immediately, and if the path we should fetch changes
  useEffect(() => {
    fetchData();
  }, [apiPath]);

  // Schedule subsequent data fetches based on refresh rate+offset
  useDriftlessInterval(
    () => {
      fetchData();
    },
    refreshRateMs,
    refreshRateOffsetMs,
  );

  useInspectorControls(fetchData, lastSuccess);

  return { apiResponse, requestCount, lastSuccess };
};

const useInspectorControls = (
  fetchData: () => void,
  lastSuccess: number | null,
): void => {
  useReceiveFromInspector((message) => {
    if (message.type == "refresh_data") fetchData();
  });

  useEffect(() => {
    if (lastSuccess) {
      sendToInspector({ type: "data_refreshed", timestamp: lastSuccess });
    }
  }, [lastSuccess]);
};

const useApiResponse = ({ id }) => useBaseApiResponse(id);

const useSimulationApiResponse = ({ id }) =>
  useBaseApiResponse(id, "simulation");

// For OFM apps--DUP, triptych--we need to request a different
// route that's more permissive of CORS, since these clients are loaded from a local html file
// (and thus their data requests to our server are cross-origin).
//
// The /dup endpoint only has the CORS stuff, and otherwise runs exactly the same backend logic as
// the normal one used by `useApiResponse`.
//
// The /triptych endpoint has the CORS stuff, plus an additional step that maps the player name of
// the individual triptych pane to a screen ID representing the collective trio.
const useDUPApiResponse = ({ id }) => useBaseApiResponse(id, "dup");
const useTriptychApiResponse = ({ id }) => useBaseApiResponse(id, "triptych");

export default useApiResponse;
export type { ApiResponse, SimulationData };
export { useSimulationApiResponse, useDUPApiResponse, useTriptychApiResponse };

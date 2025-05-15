import { WidgetData } from "Components/v2/widget";
import useDriftlessInterval from "Hooks/use_driftless_interval";
import React, { useEffect, useMemo, useState } from "react";
import { getDatasetValue } from "Util/dataset";
import { sendToInspector, useReceiveFromInspector } from "Util/inspector";
import { isDup } from "Util/outfront";
import { getScreenSide, isRealScreen } from "Util/utils";
import * as SentryLogger from "Util/sentry";
import { ROTATION_INDEX } from "Components/v2/dup/rotation_index";
import { DUP_VERSION } from "Components/v2/dup/version";
import useRefreshRate from "./use_refresh_rate";

const BASE_PATH = "/v2/api/screen";
const MINUTE_IN_MS = 60_000;
const OUTFRONT_BASE_URI = "https://screens.mbta.com";

type SimulationResponse = { full_page: WidgetData; flex_zone: WidgetData[] };

type DataResponse<T extends SimulationResponse | WidgetData> = {
  data: T;
  variants?: Record<string, T>;
};

type SimulationData = { fullPage: WidgetData; flexZone: WidgetData[] };

type Success = { state: "success"; data: WidgetData };
type SimulationSuccess = { state: "simulation_success"; data: SimulationData };
type NonSuccess =
  // The request was successful, but this screen is disabled via config.
  | { state: "disabled" }
  // Either:
  // - The request failed.
  // - The server responded, but did not successfully fetch data. Riders may
  //   still be able to find data from other sources.
  | { state: "failure" }
  // Initial state when no data has been received yet.
  | { state: "loading" };

type ApiResponse = Success | SimulationSuccess | NonSuccess;

type ApiResponseWithVariants =
  | (Success & { variants?: Record<string, WidgetData> })
  | (SimulationSuccess & { variants?: Record<string, SimulationData> })
  | NonSuccess;

const FAILURE_RESPONSE: ApiResponse = { state: "failure" };
const LOADING_RESPONSE: ApiResponse = { state: "loading" };

const parseRawResponse = (json): ApiResponseWithVariants => {
  if (json.disabled) {
    return { state: "disabled" };
  } else if (json.data) {
    if ("full_page" in json.data) {
      const { data, variants } = json as DataResponse<SimulationResponse>;

      return {
        state: "simulation_success",
        data: parseSimulationResponse(data),
        variants: Object.fromEntries(
          Object.entries(variants ?? {}).map(([variant, data]) => [
            variant,
            parseSimulationResponse(data),
          ]),
        ),
      };
    } else {
      const { data, variants } = json as DataResponse<WidgetData>;
      return { state: "success", data, variants };
    }
  } else {
    return { state: "failure" };
  }
};

const parseSimulationResponse = ({
  full_page,
  flex_zone,
}: SimulationResponse): SimulationData => ({
  fullPage: full_page,
  flexZone: flex_zone,
});

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

const isSuccess = (
  response: ApiResponse,
): response is Success | SimulationSuccess =>
  ["success", "simulation_success"].includes(response.state);

const loggingParams = () => {
  if (isDup()) {
    return {
      rotation_index: ROTATION_INDEX.toString(),
      version: DUP_VERSION,
    };
  } else {
    return {};
  }
};

const useApiPath = (screenId: string, appendPath?: string): string => {
  return useMemo(() => {
    const base = isDup() ? OUTFRONT_BASE_URI : document.baseURI;
    const path = [
      BASE_PATH,
      getDatasetValue("isPending") === "true" ? "pending" : null,
      screenId,
      appendPath,
    ]
      .filter(Boolean)
      .join("/");

    const url = new URL(path, base);

    const datasetParams: Record<string, string | null | undefined> = {
      is_real_screen: isRealScreen() ? "true" : null,
      last_refresh: getDatasetValue("lastRefresh"),
      requestor:
        getDatasetValue("requestor") ?? (isRealScreen() ? "real_screen" : null),
      screen_side: getScreenSide(),
      variant: getDatasetValue("variant"),
      ...loggingParams(),
    };

    for (const [key, value] of Object.entries(datasetParams)) {
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

const useBaseApiResponse = ({
  id,
  appendPath,
}: UseBaseApiResponseOpts): UseApiResponseReturn => {
  const { refreshRateMs, refreshRateOffsetMs } = useRefreshRate();
  const [apiResponse, setApiResponse] = useState<ApiResponse>(LOADING_RESPONSE);
  const [requestCount, setRequestCount] = useState<number>(0);
  const [lastSuccess, setLastSuccess] = useState<number | null>(null);

  const apiPath = useApiPath(id, appendPath);

  const fetchData = async () => {
    try {
      const now = Date.now();
      const result = await fetch(apiPath);
      const json = await result.json();

      if (json.force_reload) window.location.reload();

      const response = parseRawResponse(json);

      if (response.state == "failure") {
        SentryLogger.info("Request failed.", { json });
        doFailureBuffer(lastSuccess, setApiResponse, response);
      } else {
        setApiResponse((prevApiResponse) => {
          if (!isSuccess(prevApiResponse)) {
            SentryLogger.info("Exiting no-data state.");
          }
          return response;
        });
        setLastSuccess(now);
      }
    } catch (err) {
      SentryLogger.captureException(err);
      doFailureBuffer(lastSuccess, setApiResponse);
    }

    setRequestCount((count) => count + 1);
  };

  // Fetch data once, immediately, on page load
  useEffect(() => {
    fetchData();
  }, []);

  // Schedule subsequent data fetches, if we need to
  useDriftlessInterval(
    () => {
      fetchData();
    },
    refreshRateMs,
    refreshRateOffsetMs,
  );

  const variant = useInspectorVariant();
  useInspectorControls(fetchData, lastSuccess);

  return {
    apiResponse: selectVariant(apiResponse, variant),
    requestCount,
    lastSuccess,
  };
};

const selectVariant = (
  response: ApiResponseWithVariants,
  variant: string | null,
): ApiResponse => {
  if (variant && isSuccess(response) && response.variants) {
    if (variant in response.variants) {
      // This seems like it should be replacable with a less "mutable" approach
      // such as `return { ...response, data: response.variants[variant] }`, but
      // the compiler can't work out that the types are compatible. Maybe check
      // this again once we upgrade to TypeScript 5.
      const copy = { ...response };
      copy.data = response.variants[variant];
      delete copy.variants;
      return copy;
    } else {
      return FAILURE_RESPONSE;
    }
  } else {
    return response;
  }
};

const useInspectorVariant = (): string | null => {
  const [variant, setVariant] = useState<string | null>(null);

  useReceiveFromInspector((message) => {
    if (message.type == "set_data_variant") setVariant(message.variant);
  });

  return variant;
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

const useApiResponse = ({ id }): UseApiResponseReturn =>
  useBaseApiResponse({ id });

const useSimulationApiResponse = ({ id }): UseApiResponseReturn =>
  useBaseApiResponse({ id, appendPath: "simulation" });

// For OFM apps--DUPs--we need to request a different
// route that's more permissive of CORS, since these clients are loaded from a local html file
// (and thus their data requests to our server are cross-origin).
//
// The /dup endpoint only has the CORS stuff, and otherwise runs exactly the same backend logic as
// the normal one used by `useApiResponse`.
const useDUPApiResponse = ({ id }): UseApiResponseReturn =>
  useBaseApiResponse({ id, appendPath: "dup" });

export default useApiResponse;
export type { ApiResponse, SimulationData };
export { useSimulationApiResponse, useDUPApiResponse };

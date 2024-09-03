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

const MINUTE_IN_MS = 60_000;

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

const getIsRealScreenParam = () => {
  return isRealScreen() ? "&is_real_screen=true" : "";
};

const isSuccess = (response: ApiResponse) =>
  response != null &&
  ["success", "simulation_success"].includes(response.state);

const getScreenSideParam = () => {
  const screenSide = getScreenSide();
  return screenSide ? `&screen_side=${screenSide}` : "";
};

const getRequestorParam = () => {
  if (isOFM()) return `&requestor=real_screen`;

  let requestor = getDatasetValue("requestor");
  if (!requestor && isRealScreen()) {
    requestor = "real_screen";
  }

  return requestor ? `&requestor=${requestor}` : "";
};

const getLoggingParams = () => {
  if (isDup()) {
    return `&rotation_index=${ROTATION_INDEX}&version=${DUP_VERSION}`;
  }

  if (isTriptych()) {
    const triptychPane = getTriptychPane();
    return `&pane=${triptychPane || "UNKNOWN"}&version=${TRIPTYCH_VERSION}`;
  }

  return "";
};

const getOutfrontAbsolutePath = () =>
  isOFM() ? "https://screens.mbta.com" : "";

const getRoute = () => {
  const route = "/v2/api/screen/";
  const isPending = getDatasetValue("isPending") === "true";
  return isPending ? `${route}pending/` : route;
};

const getApiPath = (id: string, routePart: string) => {
  const outfrontAbsolutePath = getOutfrontAbsolutePath();
  const route = getRoute();
  const lastRefresh = getDatasetValue("lastRefresh");
  const isRealScreenParam = getIsRealScreenParam();
  const screenSideParam = getScreenSideParam();
  const requestorParam = getRequestorParam();
  const loggingParams = getLoggingParams();

  return `${outfrontAbsolutePath}${route}${id}${routePart}?last_refresh=${lastRefresh}${isRealScreenParam}${screenSideParam}${requestorParam}${loggingParams}`;
};

interface UseApiResponseArgs {
  id: string;
  routePart?: string;
}

interface UseApiResponseReturn {
  apiResponse: ApiResponse;
  requestCount: number;
  lastSuccess: number | null;
}

const useBaseApiResponse = ({
  id,
  routePart = "",
}: UseApiResponseArgs): UseApiResponseReturn => {
  const { refreshRateMs, refreshRateOffsetMs } = useRefreshRate();
  const [apiResponse, setApiResponse] = useState<ApiResponse>(LOADING_RESPONSE);
  const [requestCount, setRequestCount] = useState<number>(0);
  const [lastSuccess, setLastSuccess] = useState<number | null>(null);
  const apiPath = useMemo(() => getApiPath(id, routePart), [id, routePart]);

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

const useApiResponse = ({ id }) => useBaseApiResponse({ id, routePart: "" });

const useSimulationApiResponse = ({ id }) =>
  useBaseApiResponse({ id, routePart: "/simulation" });

// For OFM apps--DUP, triptych--we need to request a different
// route that's more permissive of CORS, since these clients are loaded from a local html file
// (and thus their data requests to our server are cross-origin).
//
// The /dup endpoint only has the CORS stuff, and otherwise runs exactly the same backend logic as
// the normal one used by `useApiResponse`.
//
// The /triptych endpoint has the CORS stuff, plus an additional step that maps the player name of
// the individual triptych pane to a screen ID representing the collective trio.
const useDUPApiResponse = ({ id }) =>
  useBaseApiResponse({ id, routePart: "/dup" });

const useTriptychApiResponse = ({ id }) =>
  useBaseApiResponse({ id, routePart: "/triptych" });

export default useApiResponse;
export type { ApiResponse, SimulationData };
export { useSimulationApiResponse, useDUPApiResponse, useTriptychApiResponse };

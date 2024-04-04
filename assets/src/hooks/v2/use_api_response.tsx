import { WidgetData } from "Components/v2/widget";
import useDriftlessInterval from "Hooks/use_driftless_interval";
import React, { useEffect, useMemo, useState } from "react";
import { fetchDatasetValue, getDatasetValue } from "Util/dataset";
import { isDup, isOFM, isTriptych, getTriptychPane } from "Util/outfront";
import { getScreenSide, isRealScreen } from "Util/util";
import * as SentryLogger from "Util/sentry";
import { ROTATION_INDEX } from "Components/v2/dup/rotation_index";
import { DUP_VERSION } from "Components/v2/dup/version";
import { TRIPTYCH_VERSION } from "Components/v2/triptych/version";

const MINUTE_IN_MS = 60_000;

interface RawResponse {
  data: WidgetData | null;
  force_reload: boolean;
  disabled: boolean;
}

interface SimulationRawResponse {
  data: {
    full_page: WidgetData;
    flex_zone: WidgetData[];
  };
  force_reload: boolean;
  disabled: boolean;
}

type ApiResponse =
  // The request was successful.
  | { state: "success"; data: WidgetData }
  | { state: "simulation_success"; data: SimulationApiResponse }
  // The request was successful, but this screen is currently disabled via config.
  | { state: "disabled" }
  // Either:
  // - The request failed.
  // - The server responded, but did not successfully fetch data. Riders may still be able to find data from other sources.
  | { state: "failure" }
  | { state: "loading" };

type SimulationApiResponse =
  // The request was successful.
  {
    fullPage: WidgetData;
    flexZone: WidgetData[];
  };

const FAILURE_RESPONSE: ApiResponse = { state: "failure" };
const LOADING_RESPONSE: ApiResponse = { state: "loading" };

const rawResponseToApiResponse = ({
  data,
  disabled,
}: RawResponse): ApiResponse => {
  if (disabled) {
    return { state: "disabled" };
  } else if (data != null) {
    return { state: "success", data };
  } else {
    return { state: "failure" };
  }
};

const rawResponseToSimulationApiResponse = ({
  data,
  disabled,
}: SimulationRawResponse): ApiResponse => {
  if (disabled) {
    return { state: "disabled" };
  } else if (data != null) {
    return {
      state: "simulation_success",
      data: {
        fullPage: data.full_page,
        flexZone: data.flex_zone,
      },
    };
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
  let route = "/v2/api/screen/";
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
  failureModeElapsedMs?: number;
  routePart?: string;
  responseHandler?: (json: any) => ApiResponse;
}

interface UseApiResponseReturn {
  apiResponse: ApiResponse;
  requestCount: number;
  lastSuccess: number | null;
}

const useBaseApiResponse = ({
  id,
  routePart = "",
  responseHandler = rawResponseToApiResponse,
}: UseApiResponseArgs): UseApiResponseReturn => {
  const [apiResponse, setApiResponse] = useState<ApiResponse>(LOADING_RESPONSE);
  const [requestCount, setRequestCount] = useState<number>(0);
  const [lastSuccess, setLastSuccess] = useState<number | null>(null);
  const refreshRate = fetchDatasetValue("refreshRate");
  const refreshRateOffset = fetchDatasetValue("refreshRateOffset");
  const screenIdsWithOffsetMap = getDatasetValue("screenIdsWithOffsetMap");
  const refreshMs = parseInt(refreshRate!, 10) * 1000;
  let refreshRateOffsetMs = parseInt(refreshRateOffset!, 10) * 1000;
  const apiPath = useMemo(() => getApiPath(id, routePart), [id, routePart]);

  if (screenIdsWithOffsetMap) {
    const screens = JSON.parse(screenIdsWithOffsetMap);

    refreshRateOffsetMs =
      screens.find((screen) => screen.id === id).refresh_rate_offset * 1000;
  }

  const fetchData = async () => {
    try {
      const now = Date.now();
      const result = await fetch(apiPath);
      const json = await result.json();

      if (json.force_reload) {
        window.location.reload();
      }

      const apiResponse = responseHandler(json);

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
    } catch (err) {
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
    refreshMs,
    refreshRateOffsetMs,
  );

  return { apiResponse, requestCount, lastSuccess };
};

const useApiResponse = ({ id }) =>
  useBaseApiResponse({
    id,
    routePart: "",
    responseHandler: rawResponseToApiResponse,
  });

const useSimulationApiResponse = ({ id }) =>
  useBaseApiResponse({
    id,
    routePart: "/simulation",
    responseHandler: rawResponseToSimulationApiResponse,
  });

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
  useBaseApiResponse({
    id,
    routePart: "/dup",
    responseHandler: rawResponseToApiResponse,
  });

const useTriptychApiResponse = ({ id }) =>
  useBaseApiResponse({
    id,
    routePart: "/triptych",
    responseHandler: rawResponseToApiResponse,
  });

export default useApiResponse;
export { ApiResponse, SimulationApiResponse };
export { useSimulationApiResponse, useDUPApiResponse, useTriptychApiResponse };

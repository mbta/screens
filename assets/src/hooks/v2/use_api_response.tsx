import { WidgetData } from "Components/v2/widget";
import useDriftlessInterval from "Hooks/use_driftless_interval";
import React, { useEffect, useState } from "react";
import { getDataset } from "Util/dataset";
import { getScreenSide, isRealScreen } from "Util/util";
import * as SentryLogger from "Util/sentry";

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
  | { state: "failure" };

type SimulationApiResponse =
  // The request was successful.
  {
    fullPage: WidgetData;
    flexZone: WidgetData[];
  };

const FAILURE_RESPONSE: ApiResponse = { state: "failure" };

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
  apiResponse: ApiResponse = FAILURE_RESPONSE
) => {
  if (lastSuccess == null) {
    // We haven't had a successful request since initial page load.
    // Continue showing the initial "no data" state.
    setApiResponse((state) => state);
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
  const isRealScreenParam = getIsRealScreenParam();
  const screenSideParam = getScreenSideParam();
  const [apiResponse, setApiResponse] = useState<ApiResponse>(FAILURE_RESPONSE);
  const [requestCount, setRequestCount] = useState<number>(0);
  const [lastSuccess, setLastSuccess] = useState<number | null>(null);
  const {
    lastRefresh,
    refreshRate,
    refreshRateOffset,
    screenIdsWithOffsetMap,
  } = getDataset();
  const refreshMs = parseInt(refreshRate, 10) * 1000;
  let refreshRateOffsetMs = parseInt(refreshRateOffset, 10) * 1000;
  const apiPath = `/v2/api/screen/${id}${routePart}?last_refresh=${lastRefresh}${isRealScreenParam}${screenSideParam}`;

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
    refreshRateOffsetMs
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

export default useApiResponse;
export { ApiResponse, SimulationApiResponse };
export { useSimulationApiResponse };

import { WidgetData } from "Components/v2/widget";
import useDriftlessInterval from "Hooks/use_driftless_interval";
import React, { useEffect, useState } from "react";
import { useLocation } from "react-router-dom";

const MINUTE_IN_MS = 60_000;

interface RawResponse {
  data: WidgetData | null;
  force_reload: boolean;
  disabled: boolean;
}

type ApiResponse =
  // The request was successful.
  | { state: "success"; data: WidgetData }
  // The request was successful, but this screen is currently disabled via config.
  | { state: "disabled" }
  // Either:
  // - The request failed.
  // - The server responded, but did not successfully fetch data. Riders may still be able to find data from other sources.
  | { state: "failure" };

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

const doFailureBuffer = (
  lastSuccess: number | null,
  failureModeElapsedMs: number,
  setApiResponse: React.Dispatch<React.SetStateAction<ApiResponse>>,
  apiResponse: ApiResponse = FAILURE_RESPONSE
) => {
  if (lastSuccess == null) {
    // We haven't had a successful request since initial page load.
    // Continue showing the initial "no data" state.
    setApiResponse((state) => state);
  } else {
    const elapsedMs = Date.now() - lastSuccess;

    if (elapsedMs < failureModeElapsedMs) {
      setApiResponse((state) => state);
    }
    if (elapsedMs >= failureModeElapsedMs) {
      setApiResponse(apiResponse);
    }
  }
};

const useQuery = () => {
  return new URLSearchParams(useLocation().search);
};

const useIsRealScreenParam = () => {
  const query = useQuery();
  const isRealScreen = query.get("is_real_screen");

  return isRealScreen === "true" ? "&is_real_screen=true" : "";
};

const useScreenSideParam = () => {
  const query = useQuery();
  const screenSide = query.get("screen_side");

  return screenSide ? `&screen_side=${screenSide}` : "";
};

interface UseApiResponseArgs {
  id: string;
  failureModeElapsedMs?: number;
}

interface UseApiResponseReturn {
  apiResponse: ApiResponse;
  requestCount: number;
  lastSuccess: number | null;
}

const useApiResponse = ({
  id,
  failureModeElapsedMs = MINUTE_IN_MS,
}: UseApiResponseArgs): UseApiResponseReturn => {
  const isRealScreenParam = useIsRealScreenParam();
  const screenSideParam = useScreenSideParam();
  const [apiResponse, setApiResponse] = useState<ApiResponse>(FAILURE_RESPONSE);
  const [requestCount, setRequestCount] = useState<number>(0);
  const [lastSuccess, setLastSuccess] = useState<number | null>(null);
  const { lastRefresh, refreshRate, refreshRateOffset } =
    document.getElementById("app").dataset;
  const refreshMs = parseInt(refreshRate, 10) * 1000;
  const refreshRateOffsetMs = parseInt(refreshRateOffset, 10) * 1000;
  const apiPath = `/v2/api/screen/${id}?last_refresh=${lastRefresh}${isRealScreenParam}${screenSideParam}`;

  const fetchData = async () => {
    try {
      const now = Date.now();
      const result = await fetch(apiPath);
      const json = (await result.json()) as RawResponse;

      if (json.force_reload) {
        window.location.reload();
      }

      const apiResponse = rawResponseToApiResponse(json);

      if (apiResponse.state == "failure") {
        doFailureBuffer(
          lastSuccess,
          failureModeElapsedMs,
          setApiResponse,
          apiResponse
        );
      } else {
        setApiResponse(apiResponse);
        setLastSuccess(now);
      }
    } catch (err) {
      doFailureBuffer(lastSuccess, failureModeElapsedMs, setApiResponse);
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

export default useApiResponse;
export { ApiResponse };

import { BlinkConfig } from "Components/v2/screen_container";
import { WidgetData } from "Components/v2/widget";
import useInterval from "Hooks/use_interval";
import React, { useEffect, useState } from "react";

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
  lastSuccess: number,
  failureModeElapsedMs: number,
  setApiResponse: React.Dispatch<React.SetStateAction<ApiResponse>>,
  apiResponse: ApiResponse = FAILURE_RESPONSE
) => {
  const elapsedMs = Date.now() - lastSuccess;

  if (elapsedMs < failureModeElapsedMs) {
    setApiResponse((state) => state);
  }
  if (elapsedMs >= failureModeElapsedMs) {
    setApiResponse(apiResponse);
  }
};

interface UseApiResponseArgs {
  id: string;
  failureModeElapsedMs?: number;
  blinkConfig?: BlinkConfig | null;
  setShowBlink: React.Dispatch<React.SetStateAction<boolean>>;
}

const useApiResponse = ({
  id,
  failureModeElapsedMs = MINUTE_IN_MS,
  blinkConfig = null,
  setShowBlink,
}: UseApiResponseArgs): ApiResponse => {
  const [apiResponse, setApiResponse] = useState<ApiResponse>(FAILURE_RESPONSE);
  const [lastSuccess, setLastSuccess] = useState<number>(Date.now());
  const [requestCount, setRequestCount] = useState<number>(0);
  const { lastRefresh, refreshRate } = document.getElementById("app").dataset;
  const refreshMs = parseInt(refreshRate, 10) * 1000;
  const apiPath = `/v2/api/screen/${id}?last_refresh=${lastRefresh}`;

  let maybeDoBlink = () => {};
  if (blinkConfig != null) {
    maybeDoBlink = () => {
      if (
        blinkConfig != null &&
        requestCount % blinkConfig.refreshesPerBlink == 0
      ) {
        setShowBlink(true);
        setTimeout(() => {
          setShowBlink(false);
        }, blinkConfig.durationMs);
      }
    };
  }

  const fetchData = async () => {
    setRequestCount((count) => count + 1);
    const now = Date.now();

    try {
      const result = await fetch(apiPath);
      const json = (await result.json()) as RawResponse;

      if (json.force_reload) {
        window.location.reload();
      }
      maybeDoBlink();

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
  };

  const intervalCallback = () => {
    fetchData();
  };

  // Perform initial data fetch once on component mount
  useEffect(intervalCallback, []);

  // Schedule subsequent data fetches, if we need to
  if (refreshMs != null) {
    useInterval(intervalCallback, refreshMs);
  }

  return apiResponse;
};

export default useApiResponse;
export { ApiResponse };

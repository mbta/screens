import { WidgetData } from "Components/v2/widget";
import useInterval from "Hooks/use_interval";
import { useEffect, useState } from "react";

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
}

const useApiResponse = ({
  id,
  failureModeElapsedMs = MINUTE_IN_MS,
}: UseApiResponseArgs): ApiResponse => {
  const [apiResponse, setApiResponse] = useState<ApiResponse>(FAILURE_RESPONSE);
  const [lastSuccess, setLastSuccess] = useState<number>(Date.now());
  const { lastRefresh, refreshRate } = document.getElementById("app").dataset;
  const refreshMs = parseInt(refreshRate, 10) * 1000;
  const apiPath = `/v2/api/screen/${id}?last_refresh=${lastRefresh}`;

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
  };

  // Perform initial data fetch once on component mount
  useEffect(() => {
    fetchData();
  }, []);

  // Schedule subsequent data fetches, if we need to
  if (refreshMs != null) {
    useInterval(() => {
      fetchData();
    }, refreshMs);
  }

  return apiResponse;
};

export default useApiResponse;
export { ApiResponse };

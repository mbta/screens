import { WidgetData } from "Components/v2/widget";
import useDriftlessInterval from "Hooks/use_driftless_interval";
import React, { useEffect, useState } from "react";
import { ApiResponse } from "./use_api_response";

const MINUTE_IN_MS = 60_000;

interface RawResponse {
  data: WidgetData | null;
  force_reload: boolean;
  disabled: boolean;
}

type SimulationApiResponse =
  // The request was successful.
  {
    fullPage: ApiResponse;
    flexZone: ApiResponse;
  };

const FAILURE_RESPONSE: SimulationApiResponse = {
  fullPage: { state: "failure" },
  flexZone: { state: "failure" },
};

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
  full_page,
  flex_zone,
}: {
  full_page: RawResponse;
  flex_zone: RawResponse;
}): SimulationApiResponse => {
  if (full_page != null) {
    return {
      fullPage: rawResponseToApiResponse(full_page),
      flexZone: rawResponseToApiResponse(flex_zone),
    };
  } else {
    return { fullPage: { state: "failure" }, flexZone: { state: "failure" } };
  }
};

const doFailureBuffer = (
  lastSuccess: number | null,
  failureModeElapsedMs: number,
  setApiResponse: React.Dispatch<React.SetStateAction<SimulationApiResponse>>,
  apiResponse: SimulationApiResponse = FAILURE_RESPONSE
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

interface UseSimulationApiResponseArgs {
  id: string;
  failureModeElapsedMs?: number;
}

interface UseSimulationApiResponseReturn {
  apiResponse: SimulationApiResponse;
  requestCount: number;
  lastSuccess: number | null;
}

const useSimulationApiResponse = ({
  id,
  failureModeElapsedMs = MINUTE_IN_MS,
}: UseSimulationApiResponseArgs): UseSimulationApiResponseReturn => {
  const [apiResponse, setApiResponse] =
    useState<SimulationApiResponse>(FAILURE_RESPONSE);
  const [requestCount, setRequestCount] = useState<number>(0);
  const [lastSuccess, setLastSuccess] = useState<number | null>(null);
  const {
    lastRefresh,
    refreshRate,
    refreshRateOffset,
    screenIdsWithOffsetMap,
  } = document.getElementById("app").dataset;
  const refreshMs = parseInt(refreshRate, 10) * 1000;
  let refreshRateOffsetMs = parseInt(refreshRateOffset, 10) * 1000;
  const apiPath = `/v2/api/screen/${id}/simulation?last_refresh=${lastRefresh}`;

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

      const apiResponse = rawResponseToSimulationApiResponse(json);

      if (
        apiResponse.fullPage.state == "failure" ||
        apiResponse.flexZone.state == "failure"
      ) {
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

export default useSimulationApiResponse;
export { SimulationApiResponse };

import { useEffect, useState } from "react";
import { isDup } from "Util/util";
import useInterval from "Hooks/use_interval";
import { useLocation } from "react-router-dom";
import * as Sentry from "@sentry/react";

const MINUTE_IN_MS = 60_000;

const FAILURE_RESPONSE = { success: false };

const doFailureBuffer = (
  lastSuccess: number | null,
  failureModeElapsedMs: number,
  setApiResponse: React.Dispatch<React.SetStateAction<object>>,
  setLastResponseWasFailure: React.Dispatch<React.SetStateAction<boolean>>,
  apiResponse: object = FAILURE_RESPONSE
) => {
  if (lastSuccess == null) {
    // We haven't had a successful request since initial page load.
    // Continue showing the initial "no data" state.
    setApiResponse((state) => state);
  } else {
    const elapsedMs = Date.now() - lastSuccess;

    // Because we recycle state when a failure occurs,
    // we need to track failures in a separate state variable.
    setLastResponseWasFailure(true);

    if (elapsedMs < failureModeElapsedMs) {
      setApiResponse((state) => state);
    }
    if (elapsedMs >= failureModeElapsedMs) {
      setApiResponse(apiResponse);
    }

    // This will trigger until a success API response is received.
    Sentry.captureMessage("API response failure encountered.");
  }
};

const useQuery = () => {
  return new URLSearchParams(useLocation().search);
};

const useIsRealScreenParam = () => {
  return isDup() || useQuery().get("is_real_screen") === "true"
    ? "&is_real_screen=true"
    : "";
};

interface UseApiResponseArgs {
  id: string;
  datetime?: string;
  rotationIndex?: number;
  refreshMs?: number;
  withWatchdog?: boolean;
  failureModeElapsedMs?: number;
}

const useApiResponse = ({
  id,
  datetime,
  rotationIndex,
  refreshMs,
  withWatchdog = false,
  failureModeElapsedMs = MINUTE_IN_MS,
}: UseApiResponseArgs) => {
  const [apiResponse, setApiResponse] = useState<object | null>(null);
  const [lastSuccess, setLastSuccess] = useState<number | null>(null);
  const [_, setLastResponseWasFailure] = useState(false);
  const lastRefresh = document.getElementById("app")?.dataset.lastRefresh;
  const isRealScreenParam = useIsRealScreenParam();

  const apiPath = buildApiPath({
    id,
    datetime,
    rotationIndex,
    lastRefresh,
    isRealScreenParam,
  });

  const fetchData = async () => {
    try {
      const now = Date.now();
      const result = await fetch(apiPath);
      const json = await result.json();

      if (json.force_reload === true) {
        window.location.reload();
      }
      if (withWatchdog) updateSolariWatchdog();

      if (json.success) {
        // If the last response was a failure, log that we are no longer failing.
        setLastResponseWasFailure((prevState) => {
          if (prevState) {
            Sentry.captureMessage("Recovered from API response failure.");
          }

          return false;
        });

        setApiResponse(json);
        setLastSuccess(now);
      } else {
        doFailureBuffer(
          lastSuccess,
          failureModeElapsedMs,
          setApiResponse,
          setLastResponseWasFailure,
          json
        );
      }
    } catch (err) {
      doFailureBuffer(
        lastSuccess,
        failureModeElapsedMs,
        setApiResponse,
        setLastResponseWasFailure
      );
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

interface BuildApiPathArgs {
  id: string;
  datetime?: string;
  rotationIndex?: number;
  lastRefresh?: string;
  isRealScreenParam: string;
}

const buildApiPath = ({
  id,
  datetime,
  rotationIndex,
  lastRefresh,
  isRealScreenParam,
}: BuildApiPathArgs) => {
  let apiPath = `/api/screen/${id}`;

  if (rotationIndex != null) {
    apiPath += `/${rotationIndex}`;
  }

  apiPath += `?last_refresh=${lastRefresh}${isRealScreenParam}`;

  if (datetime != null) {
    apiPath += `&datetime=${datetime}`;
  }

  if (isDup()) {
    apiPath = "https://screens.mbta.com" + apiPath;
  }

  return apiPath;
};

const updateSolariWatchdog = () => {
  const now = new Date().toISOString();
  localStorage.clear();
  localStorage.setItem("mainWatch", now);
};

export default useApiResponse;

import { useEffect, useState } from "react";
import { isDup, isRealScreen } from "Util/util";
import useInterval from "Hooks/use_interval";
import { getDatasetValue } from "Util/dataset";
import * as SentryLogger from "Util/sentry";

const MINUTE_IN_MS = 60_000;

const FAILURE_RESPONSE = { success: false };

const doFailureBuffer = (
  lastSuccess: number | null,
  failureModeElapsedMs: number,
  setApiResponse: React.Dispatch<React.SetStateAction<object>>,
  apiResponse: object = FAILURE_RESPONSE
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
      // This will trigger until a success API response is received.
      setApiResponse((prevApiResponse) => {
        if (prevApiResponse != null && prevApiResponse.success) {
          SentryLogger.info("Entering no-data state.");
        }
        return apiResponse;
      });
    }
  }
};

const useIsRealScreenParam = () => {
  return isRealScreen()
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
  const lastRefresh = getDatasetValue("lastRefresh");
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
        setApiResponse((prevApiResponse) => {
          if (prevApiResponse != null && !prevApiResponse.success) {
            SentryLogger.info("Exiting no-data state.");
          }
          return json;
        });
        setLastSuccess(now);
      } else {
        doFailureBuffer(
          lastSuccess,
          failureModeElapsedMs,
          setApiResponse,
          json
        );
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

import { useEffect, useState } from "react";
import { isDup } from "Util/util";
import useInterval from "Hooks/use_interval";

const MINUTE_IN_MS = 60_000;

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
  const [failureStart, setFailureStart] = useState<number | null>(null);
  const lastRefresh = document.getElementById("app").dataset.lastRefresh;

  const apiPath = buildApiPath({ id, datetime, rotationIndex, lastRefresh });

  const fetchData = async () => {
    try {
      const result = await fetch(apiPath);
      const json = await result.json();

      if (json.force_reload === true) {
        window.location.reload();
      }
      if (withWatchdog) updateSolariWatchdog();
      setApiResponse(json);
      setFailureStart(null);
    } catch (err) {
      const now = Date.now();

      if (failureStart == null) {
        setFailureStart(now);
        setApiResponse((state) => state);
      } else {
        const elapsedMs = now - failureStart;

        if (elapsedMs < failureModeElapsedMs) {
          setApiResponse((state) => state);
        }
        if (elapsedMs >= failureModeElapsedMs) {
          setApiResponse({ success: false });
        }
      }
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
}

const buildApiPath = ({
  id,
  datetime,
  rotationIndex,
  lastRefresh,
}: BuildApiPathArgs) => {
  let apiPath = `/api/screen/${id}`;

  if (rotationIndex != null) {
    apiPath += `/${rotationIndex}`;
  }

  apiPath += `?last_refresh=${lastRefresh}`;

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

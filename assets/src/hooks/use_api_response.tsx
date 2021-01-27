import { useEffect, useState } from "react";
import { isDup } from "Util/util";

interface UseApiResponseArgs {
  id: string;
  datetime?: string | null;
  rotationIndex?: number;
  refreshMs?: number;
  withWatchdog?: boolean;
}

const useApiResponse = ({
  id,
  datetime,
  rotationIndex,
  refreshMs,
  withWatchdog = false,
}: UseApiResponseArgs) => {
  const [apiResponse, setApiResponse] = useState<object | null>(null);
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
    } catch (err) {
      setApiResponse({ success: false });
    }
  };

  useEffect(() => {
    fetchData();

    if (refreshMs != null) {
      const interval = setInterval(() => {
        fetchData();
      }, refreshMs);

      return () => clearInterval(interval);
    }

    return () => undefined;
  }, []);

  return apiResponse;
};

interface BuildApiPathArgs {
  id: string;
  datetime?: string | null;
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
    apiPath = "https://screens-dev-green.mbtace.com" + apiPath;
  }

  return apiPath;
};

const updateSolariWatchdog = () => {
  const now = new Date().toISOString();
  localStorage.clear();
  localStorage.setItem("mainWatch", now);
};

export default useApiResponse;

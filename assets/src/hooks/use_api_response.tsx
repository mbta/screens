import { useEffect, useState } from "react";

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

    return () => {};
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

  return apiPath;
};

const updateSolariWatchdog = () => {
  const now = new Date().toISOString();
  localStorage.clear();
  localStorage.setItem("mainWatch", now);
};

export default useApiResponse;

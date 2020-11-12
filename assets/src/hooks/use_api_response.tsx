import { useEffect, useState } from "react";

interface BuildApiPathArgs {
  id: string;
  datetime?: string | null;
  withWatchdog?: boolean;
  rotationIndex?: number;
  lastRefresh?: string;
}

interface UseApiResponseArgs extends Omit<BuildApiPathArgs, "lastRefresh"> {
  refreshMs?: number;
}

const useApiResponse = ({
  id,
  refreshMs,
  datetime,
  withWatchdog = false,
  rotationIndex
}: UseApiResponseArgs) => {
  const [apiResponse, setApiResponse] = useState(null);
  const lastRefresh = document.getElementById("app").dataset.lastRefresh;

  const apiPath = buildApiPath({id, lastRefresh, datetime, rotationIndex});

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

const buildApiPath = ({id, lastRefresh, datetime, rotationIndex}: BuildApiPathArgs) => {
  let apiPath = `/api/screen/${id}`;
  
  if (rotationIndex != null) {
    apiPath += `/${rotationIndex}`;
  }
  
  apiPath += `?last_refresh=${lastRefresh}`;
  
  if (datetime != null) {
    apiPath += `&datetime=${datetime}`;
  }

  return apiPath;
}

const updateSolariWatchdog = () => {
  const now = new Date().toISOString();
  localStorage.clear();
  localStorage.setItem("mainWatch", now);
};

export default useApiResponse;

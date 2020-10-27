import { useEffect, useState } from "react";

const useApiResponse = (
  id,
  refreshMs,
  datetime = null,
  withWatchdog = false
) => {
  const [apiResponse, setApiResponse] = useState(null);
  const lastRefresh = document.getElementById("app").dataset.lastRefresh;

  let apiPath;
  if (datetime) {
    // http://screens-dev-green.mbtace.com
    apiPath = `http://screens-dev-green.mbtace.com/api/screen/${id}?last_refresh=${lastRefresh}&datetime=${datetime}`;
    refreshMs = 1000 * 60 * 60; // 1 per hour
  } else {
    apiPath = `http://screens-dev-green.mbtace.com/api/screen/${id}?last_refresh=${lastRefresh}`;
  }

  const fetchData = async () => {
    try {
      const result = await fetch(apiPath);
      const json = await result.json();

      if (json.force_reload === true) {
        window.location.reload(false);
      }
      if (withWatchdog) updateSolariWatchdog();
      setApiResponse(json);
    } catch (err) {
      setApiResponse({ success: false });
    }
  };

  useEffect(() => {
    fetchData();

    const interval = setInterval(() => {
      fetchData();
    }, refreshMs);

    return () => clearInterval(interval);
  }, []);

  return apiResponse;
};

const updateSolariWatchdog = () => {
  const now = new Date().toISOString();
  localStorage.clear();
  localStorage.setItem("mainWatch", now);
};

export default useApiResponse;

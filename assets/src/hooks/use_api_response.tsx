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
    apiPath = `http://localhost:4000/api/screen/${id}?last_refresh=${lastRefresh}&datetime=${datetime}`;
    refreshMs = 1000 * 60 * 60; // 1 per hour
  } else {
    apiPath = `http://localhost:4000/api/screen/${id}?last_refresh=${lastRefresh}`;
  }
  console.log("apiPath =", apiPath)

  const fetchData = async () => {
    try {
      const result = await fetch(apiPath);
      console.log("fetch result =", result)
      const json = await result.json();
      console.log("result json =", json)

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

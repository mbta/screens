import { useEffect, useState } from "react";

const useApiResponse = (id, refreshMs, date, time) => {
  const [apiResponse, setApiResponse] = useState(null);
  const apiVersion = document.getElementById("app").dataset.apiVersion;

  let apiPath;
  if (date && time) {
    apiPath = `/api/screen/${id}?version=${apiVersion}&date=${date}&time=${time}`;
    refreshMs = 1000 * 60 * 60; // 1 per hour
  } else {
    apiPath = `/api/screen/${id}?version=${apiVersion}`;
  }

  const fetchData = async () => {
    try {
      const result = await fetch(apiPath);
      const json = await result.json();

      if (json.force_reload === true) {
        window.location.reload(false);
      }
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

export default useApiResponse;

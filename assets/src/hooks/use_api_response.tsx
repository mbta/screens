import { useEffect, useState } from "react";

const useApiResponse = (id, refreshMs) => {
  const [apiResponse, setApiResponse] = useState(null);
  const apiVersion = document.getElementById("app").dataset.apiVersion;

  const fetchData = async () => {
    try {
      const result = await fetch(`/api/screen/${id}?version=${apiVersion}`);
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

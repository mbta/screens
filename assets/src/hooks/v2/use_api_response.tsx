import useInterval from "Hooks/use_interval";
import { useEffect, useState } from "react";

const MINUTE_IN_MS = 60_000;

interface UseApiResponseArgs {
  id: string;
  refreshMs?: number;
  failureModeElapsedMs?: number;
}

const useApiResponse = ({
  id,
  refreshMs,
  failureModeElapsedMs = MINUTE_IN_MS,
}) => {
  const [apiResponse, setApiResponse] = useState<object | null>(null);
  const [lastSuccess, setLastSuccess] = useState<number>(Date.now());
  const lastRefresh = document.getElementById("app").dataset.lastRefresh;
  const apiPath = `/v2/api/screen/${id}?last_refresh=${lastRefresh}`;

  const fetchData = async () => {
    try {
      const now = Date.now();
      const result = await fetch(apiPath);
      const json = await result.json();

      if (json.force_reload) {
        window.location.reload();
      }

      setApiResponse(json);
      setLastSuccess(now);
    } catch (err) {
      const elapsedMs = Date.now() - lastSuccess;

      if (elapsedMs < failureModeElapsedMs) {
        setApiResponse((state) => state);
      }
      if (elapsedMs >= failureModeElapsedMs) {
        setApiResponse({ success: false });
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

export default useApiResponse;

import { useEffect, useState } from "react";

const useApiResponse = ({ id, refreshMs }) => {
  const [apiResponse, setApiResponse] = useState(null);
  const apiPath = `/v2/api/screen/${id}`;

  const fetchData = async () => {
    const result = await fetch(apiPath);
    const json = await result.json();
    setApiResponse(json);
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

export default useApiResponse;

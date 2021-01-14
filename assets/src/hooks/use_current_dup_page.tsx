import { useEffect, useState } from "react";

const useCurrentPage = () => {
  const [page, setPage] = useState(0);

  useEffect(() => {
    const interval = setInterval(() => {
      setPage((p) => 1 - p);
    }, 3750);
    return () => clearInterval(interval);
  }, []);

  return page;
};

export default useCurrentPage;

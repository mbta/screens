import { useEffect, useState } from "react";

const useCurrentPage = () => {
  const [page, setPage] = useState(0);
  const [paging, setPaging] = useState(false);

  let mraid;

  try {
    mraid = parent?.parent?.mraid;
  } catch (_) {}

  useEffect(() => {
    if (mraid) {
      const layoutID = mraid.requestInit();
      mraid.addEventListener(
        mraid.EVENTS.ONSCREEN,
        () => setPaging(true),
        layoutID
      );
    } else {
      setPaging(true);
    }
  }, []);

  useEffect(() => {
    if (paging) {
      const interval = setInterval(() => {
        setPage((p) => 1 - p);
      }, 3750);
      return () => clearInterval(interval);
    }
  }, [paging]);

  return page;
};

export default useCurrentPage;

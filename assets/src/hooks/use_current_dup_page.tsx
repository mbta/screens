import { useEffect, useState } from "react";
import { getMRAID } from "Util/outfront";

const useCurrentPage = () => {
  const [page, setPage] = useState(0);
  const [paging, setPaging] = useState(false);

  useEffect(() => {
    const mraid = getMRAID();

    if (mraid) {
      const layoutID = mraid.requestInit();
      mraid.addEventListener(
        mraid.EVENTS.ONSCREEN,
        () => setPaging(true),
        layoutID,
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
    } else {
      return () => {};
    }
  }, [paging]);

  return page;
};

export default useCurrentPage;

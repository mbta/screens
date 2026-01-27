import {
  type ComponentType,
  type PropsWithChildren,
  createContext,
  useContext,
  useEffect,
  useState,
} from "react";

import { getMRAID } from "Util/outfront";

const Context = createContext(0);

export const useCurrentPage = () => useContext(Context);

export const Provider: ComponentType<PropsWithChildren> = ({ children }) => {
  const [page, setPage] = useState(0);
  const [isPaging, setIsPaging] = useState(false);

  useEffect(() => {
    const mraid = getMRAID();

    if (mraid) {
      const layoutID = mraid.requestInit();

      mraid.addEventListener(
        mraid.EVENTS.ONSCREEN,
        () => setIsPaging(true),
        layoutID,
      );
    } else {
      setIsPaging(true);
    }
  }, []);

  useEffect(() => {
    if (isPaging) {
      const interval = setInterval(() => setPage((p) => 1 - p), 3750);
      return () => clearInterval(interval);
    } else {
      return () => {};
    }
  }, [isPaging]);

  return <Context.Provider value={page}>{children}</Context.Provider>;
};

import { useEffect, useState } from "react";
import { getMRAID } from "Util/outfront";

const useIsOnScreen = () => {
  const [onScreen, setOnScreen] = useState(false);

  useEffect(() => {
    const mraid = getMRAID();

    if (mraid) {
      const layoutID = mraid.requestInit();
      mraid.addEventListener(
        mraid.EVENTS.ONSCREEN,
        () => setOnScreen(true),
        layoutID,
      );
    } else {
      // If in-browser, onScreen = true
      setOnScreen(true);
    }
  }, []);

  return onScreen;
};

export default useIsOnScreen;

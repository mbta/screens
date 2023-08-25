import { useEffect, useState } from "react";

const useOutfrontPlayerName = () => {
  const [playerName, setPlayerName] = useState("");

  useEffect(() => {
    if (parent?.parent?.mraid ?? false) {
      const mraid = parent.parent.mraid;
      try {
        const deviceInfo = mraid.getDeviceInfo();
        const info = JSON.parse(deviceInfo);
        setPlayerName(info.deviceName)
      } catch (err) {
        setPlayerName("noMraid");
      }
    }
    // Will rerun if MRAID changes
  }, [parent?.parent?.mraid]);
  
  return playerName !== "" ? playerName : null;
};

export default useOutfrontPlayerName;

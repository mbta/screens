import { useEffect, useState } from "react";

const useOutfrontPlayerName = () => {
  const [playerName, setPlayerName] = useState(null);

  useEffect(() => {
    if (parent?.parent?.mraid ?? false) {
      try {
        const info = JSON.parse(mraid.getDeviceInfo());
        setPlayerName(info.deviceName)
      } catch (err) {
        setPlayerName(null);
      }
    }
  }, [parent?.parent?.mraid]);
  
  return playerName;
};

export default useOutfrontPlayerName;

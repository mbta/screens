import { useEffect, useState } from "react";

const useOutfrontPlayerName = () => {
  const [playerName, setPlayerName] = useState("");

  useEffect(() => {
    console.log("Running the useEffect hook")
    if (parent?.parent?.mraid ?? false) {
      console.log("  Within the condition: parent?.parent?.mraid == true")
      try {
        console.log("   Within the try. Attempting to getDeviceInfo and parse the result")
        const deviceInfo = mraid.getDeviceInfo();
        console.log("   result of getDeviceInfo: ", deviceInfo)
        const info = JSON.parse(deviceInfo);
        console.log("   result of JSON.parse: ", info)
        setPlayerName(info.deviceName)
      } catch (err) {
        console.log("   Within the catch. Setting deviceName to `noMraid`")
        setPlayerName("noMraid");
      }
    }
    // Will rerun if MRAID changes
  }, [parent?.parent?.mraid]);
  
  if (playerName.length > 0) { 
    console.log("useOutfrontPlayerName hook has finished. Returning current state of playerName: ", playerName)
  }
  return playerName;
};

export default useOutfrontPlayerName;

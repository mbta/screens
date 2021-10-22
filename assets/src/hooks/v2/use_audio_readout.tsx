import { AudioConfig } from "Components/v2/screen_container";
import useInterval from "Hooks/use_interval";
import { useEffect } from "react";

interface UseAudioReadoutArgs {
  id: string;
  config: AudioConfig;
}

const useAudioReadout = ({
  id,
  config
}: UseAudioReadoutArgs): void => {
  if (config === null || config === undefined) {
    return;
  }

  const readoutInterval = config.readoutIntervalMinutes * 60000;
  const apiPath = `/v2/audio/${id}/readout.mp3`;

  const fetchAudio = async () => {
    try {
      const result = await fetch(apiPath);
      const blob = await result.blob();
      const url = URL.createObjectURL(blob);
      const audio = new Audio(url);
      audio.onended = (_e) => {
        URL.revokeObjectURL(url);
      };
      audio.volume = config.volume;
      audio.play();
    } catch (err) {
      console.log(err);
    }
  };

  // Perform initial data fetch once on component mount
  useEffect(() => {
    fetchAudio();
  }, []);

  // Schedule subsequent data fetches, if we need to
  if (readoutInterval != null) {
    useInterval(() => {
      fetchAudio();
    }, readoutInterval);
  }
};

export default useAudioReadout;

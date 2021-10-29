import { AudioConfig } from "Components/v2/screen_container";
import useInterval from "Hooks/use_interval";
import { useEffect } from "react";

interface UseAudioReadoutArgs {
  id: string;
  config: AudioConfig | null;
}

const useAudioReadout = ({
  id,
  config
}: UseAudioReadoutArgs): void => {
  if (config === null || config === undefined || config.readoutIntervalMinutes === 0) {
    return;
  }

  const readoutInterval = config.readoutIntervalMinutes * 60000;
  const readoutPath = `/v2/audio/${id}/readout.mp3`;
  const volumePath = `/v2/audio/${id}/volume`;

  const fetchAudio = async () => {
    try {
      const readoutData = await fetch(readoutPath);
      const volumeData = await fetch(volumePath);

      const { volume } = await volumeData.json();

      const blob = await readoutData.blob();
      const url = URL.createObjectURL(blob);
      const audio = new Audio(url);
      audio.onended = (_e) => {
        URL.revokeObjectURL(url);
      };

      audio.volume = volume;
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

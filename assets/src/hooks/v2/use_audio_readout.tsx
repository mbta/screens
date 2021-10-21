import useInterval from "Hooks/use_interval";
import { useEffect } from "react";

interface UseAudioReadoutArgs {
  id: string;
  readoutIntervalMinutes: number;
  volume: number;
}

const useAudioReadout = ({
  id,
  readoutIntervalMinutes,
  volume
}: UseAudioReadoutArgs): void => {
  const readoutInterval = readoutIntervalMinutes * 60000;
  const apiPath = `/v2/audio/${id}/readout.mp3`;

  const fetchAudio = async () => {
    try {
      const result = await fetch(apiPath);
      const blob = await result.blob();
      const url = URL.createObjectURL(blob);
      const audio = new Audio(url);
      audio.volume = volume ? +volume : 0.0;
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

import { AudioConfig } from "Components/v2/screen_container";
import useInterval from "Hooks/use_interval";
import { useEffect, useState } from "react";

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

  const intervalOffsetSeconds = config.intervalOffsetSeconds;
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

  const [skipInterval, setSkipInterval] = useState(true)

  // Perform initial data fetch once on component mount
  useEffect(() => {
    // get milliseconds until next 5m timestamp 
    const now = new Date();
    const minutes = now.getMinutes();
    const seconds = now.getSeconds();
    const milliseconds = now.getMilliseconds()
    const minutesUntilMs = (5 - minutes % 5 - 1) * 60 * 1000;
    const secondsUntilMs = (59 - seconds) * 1000;
    const millisecondsUntil = 1000 - milliseconds;
    // add offset to initial audio fetch to stagger audio readouts
    const initialOffset = minutesUntilMs + secondsUntilMs + millisecondsUntil + (intervalOffsetSeconds * 1000)

    setTimeout(() => {
      fetchAudio();
      setSkipInterval(false);
    }, initialOffset)
  }, []);

  // Schedule subsequent data fetches once initial fetch is run and skipInterval is set to false
  useInterval(() => {
    fetchAudio();
  }, readoutInterval, skipInterval);
};

export default useAudioReadout;

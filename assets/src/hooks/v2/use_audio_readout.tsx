import { AudioConfig } from "Components/v2/screen_container";
import useDriftlessInterval from "Hooks/use_driftless_interval";
import { fetchDatasetValue, getDataset } from "Util/dataset";

const readoutPath = (id: string) => `/v2/audio/${id}/readout.mp3`;
const volumePath = (id: string) => `/v2/audio/${id}/volume`;

const fetchAudio = async (id: string) => {
  try {
    const readoutData = await fetch(readoutPath(id));
    const volumeData = await fetch(volumePath(id));

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

interface UseAudioReadoutArgs {
  id: string;
  config: AudioConfig | null;
}

const useAudioReadout = ({
  id,
  config
}: UseAudioReadoutArgs): void => {
  if (config == null || config.readoutIntervalMinutes === 0) {
    return;
  }

  const intervalPeriodMs = config.readoutIntervalMinutes * 60000;

  const refreshRateOffsetMs = parseInt(fetchDatasetValue("refreshRateOffset"), 10) * 1000;
  const intervalOffsetSeconds = config.intervalOffsetSeconds;
  const intervalOffsetMs = refreshRateOffsetMs + (intervalOffsetSeconds * 1000);

  useDriftlessInterval(() => {
    fetchAudio(id);
  }, intervalPeriodMs, intervalOffsetMs);
};

export default useAudioReadout;

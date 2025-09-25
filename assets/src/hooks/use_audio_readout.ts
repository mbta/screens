import { AudioConfig } from "Components/screen_container";
import useDriftlessInterval from "Hooks/use_driftless_interval";
import { fetchDatasetValue } from "Util/dataset";
import { isFramed, sendToInspector } from "Util/inspector";

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

const DISABLED_CONFIG = { intervalOffsetSeconds: 0, readoutIntervalMinutes: 0 };

const makeConfig = (config: AudioConfig | null): AudioConfig => {
  if (!config) {
    return DISABLED_CONFIG;
  } else if (isFramed()) {
    // Don't read out periodic audio in the inspector, since there's otherwise
    // no way to turn it off. Just report the config that would have been used.
    sendToInspector({ type: "audio_config", config: config });
    return DISABLED_CONFIG;
  } else {
    return config;
  }
};

interface UseAudioReadoutArgs {
  id: string;
  config: AudioConfig | null;
}

const useAudioReadout = ({ id, config }: UseAudioReadoutArgs): void => {
  const { intervalOffsetSeconds, readoutIntervalMinutes } = makeConfig(config);

  const intervalPeriodMs = readoutIntervalMinutes * 60000;

  const refreshRateOffsetMs =
    parseInt(fetchDatasetValue("refreshRateOffset"), 10) * 1000;

  const intervalOffsetMs = refreshRateOffsetMs + intervalOffsetSeconds * 1000;

  useDriftlessInterval(
    () => {
      fetchAudio(id);
    },
    intervalPeriodMs,
    intervalOffsetMs,
  );
};

export default useAudioReadout;

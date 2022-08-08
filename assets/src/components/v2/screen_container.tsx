import React, {
  createContext,
  useContext,
  ComponentType,
  useState,
  useEffect,
} from "react";
import useApiResponse, {
  ApiResponse,
  SimulationApiResponse,
} from "Hooks/v2/use_api_response";
import Widget, { WidgetData } from "Components/v2/widget";
import useAudioReadout from "Hooks/v2/use_audio_readout";

type ResponseMapper = (
  apiResponse: ApiResponse
) => WidgetData | SimulationApiResponse;

const defaultResponseMapper: ResponseMapper = (apiResponse) => {
  switch (apiResponse.state) {
    case "success":
      return apiResponse.data;
    case "simulation_success":
      return {
        fullPage: apiResponse.data.fullPage,
        flexZone: apiResponse.data.flexZone,
      };
    case "disabled":
    case "failure":
      return { type: "no_data" };
    case "loading":
      return { type: "page_load_no_data" };
  }
};

const LOADING_LAYOUT = {
  full_screen: {
    type: "page_load_no_data",
  },
  type: "screen_takeover",
};

const ResponseMapperContext = createContext<ResponseMapper>(
  defaultResponseMapper
);

/* "Blink" info
 *
 * Some screens need to have their pixels "flipped" every so often in order to
 * reduce burn-in. The "blink" context set on a per-screen-type basis
 * dictates whether, how frequently, and for what duration this occurs.
 *
 * Blink frequency is defined relative to screen data refreshes by
 * `refreshesPerBlink`, in order to have blinks sync up with data refreshes.
 * E.g. if a given app's refresh rate is 20 sec and `refreshesPerBlink` is 15,
 * a blink will occur every 20 sec * 15 = 300 sec = 5 min.
 *
 * What the "blink" element looks like is up to you--define styles as
 * appropriate on the "screen-container-blink" class.
 */

interface BlinkConfig {
  refreshesPerBlink: number;
  durationMs: number;
}

const defaultBlinkConfig = null;

const BlinkConfigContext = createContext<BlinkConfig | null>(
  defaultBlinkConfig
);

interface AudioConfig {
  intervalOffsetSeconds: number;
  readoutIntervalMinutes: number;
}

const defaultAudioConfig = null;

const AudioConfigContext = createContext<AudioConfig | null>(
  defaultAudioConfig
);

const LastFetchContext = createContext<number | null>(null);

interface ScreenLayoutProps {
  apiResponse: ApiResponse;
  showBlink: boolean;
}

const ScreenLayout: ComponentType<ScreenLayoutProps> = ({
  apiResponse,
  showBlink,
}) => {
  const responseMapper = useContext(ResponseMapperContext);

  return (
    <div className="screen-container">
      {apiResponse && <Widget data={responseMapper(apiResponse)} />}
      {showBlink && <div className="screen-container-blink" />}
    </div>
  );
};

const ScreenContainer = ({ id }) => {
  const blinkConfig = useContext(BlinkConfigContext);
  const audioConfig = useContext(AudioConfigContext);
  const [showBlink, setShowBlink] = useState(false);

  const { apiResponse, requestCount, lastSuccess } = useApiResponse({ id });

  useAudioReadout({ id, config: audioConfig });

  useEffect(() => {
    if (
      blinkConfig != null &&
      requestCount % blinkConfig.refreshesPerBlink == 0
    ) {
      setShowBlink(true);

      setTimeout(() => {
        setShowBlink(false);
      }, blinkConfig.durationMs);
    }
  }, [requestCount]);

  return (
    <LastFetchContext.Provider value={lastSuccess}>
      <ScreenLayout apiResponse={apiResponse} showBlink={showBlink} />
    </LastFetchContext.Provider>
  );
};

export default ScreenContainer;
export {
  ResponseMapper,
  ResponseMapperContext,
  defaultResponseMapper,
  LOADING_LAYOUT,
};
export { BlinkConfig, BlinkConfigContext };
export { AudioConfig, AudioConfigContext };
export { LastFetchContext };
